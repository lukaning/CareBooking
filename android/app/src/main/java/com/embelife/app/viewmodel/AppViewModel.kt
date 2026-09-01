package com.embelife.app.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.embelife.app.model.Booking
import com.embelife.app.model.BookingChecklistTask
import com.embelife.app.model.BookingStatus
import com.embelife.app.model.OnboardingServiceCatalog
import com.embelife.app.model.Provider
import com.embelife.app.model.ServiceCategory
import com.embelife.app.model.UserProfile
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.UUID

enum class AppFlow { Auth, Onboarding, Main }

enum class UserRole { Client, Provider }

enum class LocationChoice { Current, Custom }

/**
 * Port of `EmBeLife/Models/AppModel.swift`. SwiftUI's `@Observable` becomes a `ViewModel`
 * holding Compose snapshot state, which gives the same automatic recomposition.
 */
class AppViewModel : ViewModel() {

    var flow by mutableStateOf(AppFlow.Onboarding)
    var isSignedIn by mutableStateOf(false)
    var hasCompletedOnboarding by mutableStateOf(false)

    /** When true, onboarding skips the welcome step (e.g. after sign-in/sign-up). */
    var skipWelcomeStep by mutableStateOf(false)

    var userName by mutableStateOf("")
    var userEmail by mutableStateOf("")
    var preferredLanguage by mutableStateOf("English")
    var selectedRole by mutableStateOf<UserRole?>(null)

    val selectedServiceIDs = mutableStateListOf<String>()

    /** Flat chip selections, or Level 3 leaf selections for nested categories. */
    val selectedSubServiceIDs = mutableStateMapOf<String, Set<String>>()

    /** Level 2 group selections for nested categories (e.g. Acupuncture under Therapeutic). */
    val selectedServiceGroupIDs = mutableStateMapOf<String, Set<String>>()

    /** Optional notes / descriptions keyed by Level 3 option id. */
    val serviceOptionNotes = mutableStateMapOf<String, String>()

    var locationChoice by mutableStateOf<LocationChoice?>(null)
    var customLocation by mutableStateOf("")
    var customAddress by mutableStateOf("")
    var customZipcode by mutableStateOf("")
    var searchRadiusMiles by mutableStateOf(25f)

    /** Confirmed via the in-panel Confirm button (current or custom). */
    var locationConfirmed by mutableStateOf(false)
    var resolvedCurrentAddress by mutableStateOf("")

    var profile by mutableStateOf(UserProfile())

    val bookings = mutableStateListOf<Booking>()

    /** Tasks the client saved to reuse on a later booking. */
    val savedTaskTemplates = mutableStateListOf<BookingChecklistTask>()

    val providers = mutableStateListOf<Provider>().apply { addAll(Provider.samples) }

    // MARK: - Auth

    fun completeSignIn(email: String, name: String = "") {
        userEmail = email
        if (name.isNotEmpty()) userName = name
        isSignedIn = true
        syncProfileBasics()
        if (hasCompletedOnboarding) {
            flow = AppFlow.Main
        } else {
            skipWelcomeStep = true
            flow = AppFlow.Onboarding
        }
    }

    fun completeSignUp(name: String, email: String) {
        userName = name
        userEmail = email
        isSignedIn = true
        syncProfileBasics()
        skipWelcomeStep = true
        flow = AppFlow.Onboarding
    }

    fun showAuth() {
        flow = AppFlow.Auth
    }

    fun showWelcome() {
        skipWelcomeStep = false
        flow = AppFlow.Onboarding
    }

    fun signOut() {
        isSignedIn = false
        hasCompletedOnboarding = false
        selectedRole = null
        selectedServiceIDs.clear()
        selectedSubServiceIDs.clear()
        selectedServiceGroupIDs.clear()
        serviceOptionNotes.clear()
        locationChoice = null
        customLocation = ""
        customAddress = ""
        customZipcode = ""
        locationConfirmed = false
        resolvedCurrentAddress = ""
        profile = UserProfile()
        bookings.clear()
        skipWelcomeStep = false
        flow = AppFlow.Onboarding
    }

    // MARK: - Onboarding

    fun finishOnboarding() {
        hasCompletedOnboarding = true
        if (profile.address.isEmpty()) {
            when (locationChoice) {
                LocationChoice.Current ->
                    profile = profile.copy(
                        address = resolvedCurrentAddress.ifEmpty { "Current location" },
                    )

                LocationChoice.Custom ->
                    profile = if (customAddress.isNotEmpty()) {
                        profile.copy(
                            address = listOf(customAddress, customZipcode)
                                .filter { it.isNotEmpty() }
                                .joinToString(", "),
                        )
                    } else {
                        profile.copy(address = customLocation)
                    }

                null -> Unit
            }
        }
        if (profile.servicesRequestedFor.isEmpty()) {
            val titles = ServiceCategory.all
                .filter { selectedServiceIDs.contains(it.id) }
                .map { it.title }
            profile = profile.copy(
                servicesRequestedFor = if (titles.isEmpty()) {
                    selectedSubServiceLabels.joinToString(", ")
                } else {
                    titles.take(3).joinToString(", ")
                },
            )
        }
        flow = AppFlow.Main
    }

    val selectedSubServiceLabels: List<String>
        get() = selectedSubServiceIDs.flatMap { (categoryID, ids) ->
            OnboardingServiceCatalog.allLeafOptions(categoryID)
                .filter { ids.contains(it.id) }
                .map { it.title }
        }

    fun clearServiceSelections(categoryID: String) {
        selectedSubServiceIDs[categoryID].orEmpty().forEach { serviceOptionNotes.remove(it) }
        selectedSubServiceIDs[categoryID] = emptySet()
        selectedServiceGroupIDs[categoryID] = emptySet()
    }

    // MARK: - Bookings

    fun addBooking(booking: Booking) {
        bookings.add(0, booking)
    }

    fun updateBooking(booking: Booking) {
        val index = bookings.indexOfFirst { it.id == booking.id }
        if (index >= 0) bookings[index] = booking
    }

    /** Append care tasks to a Requested or Booked appointment checklist. */
    fun appendChecklistTasks(bookingID: UUID, tasks: List<BookingChecklistTask>) {
        if (tasks.isEmpty()) return
        val index = bookings.indexOfFirst { it.id == bookingID }
        if (index < 0) return
        val booking = bookings[index]
        if (booking.status == BookingStatus.Completed) return
        bookings[index] = booking.copy(checklistTasks = booking.checklistTasks + tasks)
    }

    fun removeChecklistTask(bookingID: UUID, taskID: UUID) {
        val index = bookings.indexOfFirst { it.id == bookingID }
        if (index < 0) return
        val booking = bookings[index]
        bookings[index] = booking.copy(
            checklistTasks = booking.checklistTasks.filterNot { it.id == taskID },
        )
    }

    fun replaceChecklistTask(bookingID: UUID, task: BookingChecklistTask) {
        val index = bookings.indexOfFirst { it.id == bookingID }
        if (index < 0) return
        val booking = bookings[index]
        bookings[index] = booking.copy(
            checklistTasks = booking.checklistTasks.map { if (it.id == task.id) task else it },
        )
    }

    fun saveTaskForNextTime(task: BookingChecklistTask) {
        val template = task.copiedAsTemplate()
        val alreadySaved = savedTaskTemplates.any {
            it.title == template.title && it.category == template.category
        }
        if (!alreadySaved) savedTaskTemplates.add(template)
    }

    /** Append a sub-task under an existing checklist item on a Requested or Booked visit. */
    fun appendSubtask(bookingID: UUID, parentTaskID: UUID, subtask: BookingChecklistTask) {
        val index = bookings.indexOfFirst { it.id == bookingID }
        if (index < 0) return
        val booking = bookings[index]
        if (booking.status == BookingStatus.Completed) return
        bookings[index] = booking.copy(
            checklistTasks = booking.checklistTasks.map { existing ->
                if (existing.id == parentTaskID) {
                    existing.copy(subtasks = existing.subtasks + subtask)
                } else {
                    existing
                }
            },
        )
    }

    fun rescheduleBooking(
        id: UUID,
        date: LocalDate,
        startTime: LocalDateTime,
        reason: String = "",
        message: String = "",
    ) {
        val index = bookings.indexOfFirst { it.id == id }
        if (index < 0) return
        bookings[index] = bookings[index].copy(
            date = date,
            startTime = startTime,
            rescheduleReason = reason.trim().ifEmpty { null },
            rescheduleMessage = message.trim().ifEmpty { null },
        )
    }

    fun cancelBooking(id: UUID) {
        bookings.removeAll { it.id == id }
    }

    fun booking(id: UUID): Booking? = bookings.firstOrNull { it.id == id }

    fun submitBookingReview(bookingID: UUID, rating: Int, text: String) {
        val index = bookings.indexOfFirst { it.id == bookingID }
        if (index < 0) return
        bookings[index] = bookings[index].copy(
            clientReviewRating = rating.coerceIn(1, 5),
            clientReviewText = text.trim(),
        )
    }

    /** Seeds sample Requested / Booked / Completed items when the list is empty. */
    fun seedBookingsIfNeeded() {
        if (bookings.isNotEmpty() || providers.size < 2) return

        val today = LocalDate.now()
        fun slot(days: Long, hour: Int): Pair<LocalDate, LocalDateTime> {
            val date = today.plusDays(days)
            return date to LocalDateTime.of(date, LocalTime.of(hour, 0))
        }

        val (bookedDate, bookedStart) = slot(3, 10)
        val (requestedDate, requestedStart) = slot(7, 15)
        val (completedDate, completedStart) = slot(-5, 14)

        bookings.addAll(
            listOf(
                Booking(
                    provider = providers[0],
                    date = bookedDate,
                    startTime = bookedStart,
                    durationMinutes = 120,
                    status = BookingStatus.Booked,
                    serviceProvidedTo = "Parent",
                ),
                Booking(
                    provider = providers[0],
                    date = requestedDate,
                    startTime = requestedStart,
                    durationMinutes = 120,
                    status = BookingStatus.Requested,
                    serviceProvidedTo = "S. Roger",
                ),
                Booking(
                    provider = providers[0],
                    date = completedDate,
                    startTime = completedStart,
                    durationMinutes = 120,
                    status = BookingStatus.Completed,
                    serviceProvidedTo = "S. Roger",
                ),
            ),
        )
    }

    private fun syncProfileBasics() {
        var next = profile
        if (next.firstName.isEmpty() && userName.isNotEmpty()) {
            val parts = userName.split(" ").filter { it.isNotEmpty() }
            next = next.copy(
                firstName = parts.firstOrNull() ?: "",
                lastName = if (parts.size > 1) parts.drop(1).joinToString(" ") else next.lastName,
            )
        }
        if (next.email.isEmpty()) next = next.copy(email = userEmail)
        profile = next
    }
}
