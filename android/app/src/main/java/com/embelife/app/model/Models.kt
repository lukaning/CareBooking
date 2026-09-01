package com.embelife.app.model

import com.embelife.app.R
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

data class Provider(
    val id: String,
    val name: String,
    val title: String,
    val ratePerHour: Int,
    val rating: Double,
    val reviewCount: Int,
    val bio: String,
    val specialties: String,
    val bookingCount: Int,
    val imageRes: Int,
) {
    companion object {
        val samples: List<Provider> = listOf(
            Provider(
                id = "eric",
                name = "Eric Acmen",
                title = "Personal Care Aide",
                ratePerHour = 25,
                rating = 4.8,
                reviewCount = 5,
                bio = "I believe that every child is unique, and I tailor my care to meet the individual needs and personalities of each child in my care.",
                specialties = "Specialties: meal prep, light housekeeping, running errands",
                bookingCount = 56,
                imageRes = R.drawable.provider_avatar,
            ),
            Provider(
                id = "maya",
                name = "Maya Chen",
                title = "Postpartum Doula",
                ratePerHour = 40,
                rating = 4.9,
                reviewCount = 18,
                bio = "I support families through the early postpartum weeks with feeding guidance, recovery care, and calm companionship.",
                specialties = "Specialties: lactation support, newborn care, overnight support",
                bookingCount = 112,
                imageRes = R.drawable.provider_avatar,
            ),
            Provider(
                id = "jordan",
                name = "Jordan Lee",
                title = "Companion Care",
                ratePerHour = 28,
                rating = 4.7,
                reviewCount = 9,
                bio = "I focus on meaningful conversation, light activity, and helping clients stay connected to daily routines.",
                specialties = "Specialties: companionship, transportation, grocery help",
                bookingCount = 41,
                imageRes = R.drawable.provider_avatar,
            ),
        )
    }
}

data class ServiceCategory(
    val id: String,
    val title: String,
    val imageRes: Int,
    val selectedImageRes: Int? = null,
) {
    companion object {
        val all: List<ServiceCategory> = listOf(
            ServiceCategory(
                id = "personal",
                title = "Personal Care/Activities of Daily Living Services",
                imageRes = R.drawable.svc_personal_care,
                selectedImageRes = R.drawable.svc_personal_care_selected,
            ),
            ServiceCategory(
                id = "birth",
                title = "Birth, Newborn & Postpartum Services",
                imageRes = R.drawable.svc_birth,
            ),
            ServiceCategory(
                id = "therapeutic",
                title = "Therapeutic and Rehabilitation Services",
                imageRes = R.drawable.svc_rehab,
            ),
            ServiceCategory(
                id = "nutrition",
                title = "Nutrition & Dietary Services",
                imageRes = R.drawable.svc_dietary,
            ),
            ServiceCategory(
                id = "bereavement",
                title = "Loss, Bereavement & End of Life Services",
                imageRes = R.drawable.svc_bereavement,
            ),
        )
    }
}

enum class BookingStatus {
    Requested,
    Booked,
    Completed;

    val tab: BookingTab
        get() = when (this) {
            Requested -> BookingTab.Requested
            Booked -> BookingTab.Booked
            Completed -> BookingTab.Completed
        }
}

enum class BookingTab(val title: String, val shortTitle: String) {
    Requested("Requested", "Request"),
    Booked("Booked", "Booked"),
    Completed("Completed", "Completed"),
}

enum class BookingTaskPriority(val label: String) {
    Low("Low"),
    Medium("Medium"),
    High("High"),
}

private val timeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a")
private val abbreviatedDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")

data class BookingChecklistTask(
    val id: UUID = UUID.randomUUID(),
    var title: String,
    /** Top-level service category label (e.g. Personal Care). */
    var category: String,
    /** Leaf / subcategory label when selected from catalog. */
    var subcategory: String = "",
    var priority: BookingTaskPriority = BookingTaskPriority.Medium,
    var deadline: LocalDateTime? = null,
    var detailDescription: String = "",
    var estimatedMinutes: Int? = null,
    var attachmentNames: List<String> = emptyList(),
    var subtasks: List<BookingChecklistTask> = emptyList(),
) {
    val categoryPathLabel: String
        get() = if (subcategory.isEmpty()) category else "$category · $subcategory"

    val scheduleSubtitle: String?
        get() {
            deadline?.let {
                val time = it.format(timeFormatter)
                return if (it.toLocalDate() == LocalDate.now()) {
                    "Today at $time"
                } else {
                    "${it.format(abbreviatedDateFormatter)} at $time"
                }
            }
            return estimatedMinutes?.let { estimateLabel(it) }
        }

    fun copiedAsTemplate(): BookingChecklistTask = copy(
        id = UUID.randomUUID(),
        subtasks = subtasks.map { it.copiedAsTemplate() },
    )

    companion object {
        val estimateOptions = listOf("15 min", "30 min", "45 min", "1 hour", "1.5 hours", "2 hours")

        fun minutesFromEstimateLabel(label: String): Int? = when (label) {
            "15 min" -> 15
            "30 min" -> 30
            "45 min" -> 45
            "1 hour" -> 60
            "1.5 hours" -> 90
            "2 hours" -> 120
            else -> null
        }

        fun estimateLabel(minutes: Int): String = when (minutes) {
            15 -> "15 min"
            30 -> "30 min"
            45 -> "45 min"
            60 -> "1 hour"
            90 -> "1.5 hours"
            120 -> "2 hours"
            else -> "$minutes min"
        }
    }
}

data class Booking(
    val id: UUID = UUID.randomUUID(),
    val provider: Provider,
    var date: LocalDate,
    var startTime: LocalDateTime,
    var durationMinutes: Int,
    var status: BookingStatus = BookingStatus.Requested,
    var serviceProvidedTo: String = "",
    var title: String = "Spear Street Household Task",
    var taskDescription: String = "This task is aimed at taking care of daily chores and some lightweight cooking and taking care of this and that.",
    var location: String = "San Francisco, Detailed Location",
    var dateCreated: LocalDateTime = LocalDateTime.now(),
    var checklistTasks: List<BookingChecklistTask> = defaultChecklist(),
    /** Client star rating left after a completed visit (1…5). */
    var clientReviewRating: Int? = null,
    /** Optional free-text review left with the rating. */
    var clientReviewText: String? = null,
    /** Last reschedule proposal reason (optional). */
    var rescheduleReason: String? = null,
    /** Last reschedule note sent to the provider (optional). */
    var rescheduleMessage: String? = null,
) {
    val hasClientReview: Boolean
        get() = (clientReviewRating ?: 0) > 0

    val endTime: LocalDateTime
        get() = startTime.plus(Duration.ofMinutes(durationMinutes.toLong()))

    val timeRangeLabel: String
        get() = "${startTime.format(timeFormatter)} - ${endTime.format(timeFormatter)}"

    val timeRangeWithDurationLabel: String
        get() {
            val hours = durationMinutes / 60
            val duration = if (hours == 1) "1 Hour" else "$hours Hours"
            return "$timeRangeLabel ($duration)"
        }

    companion object {
        private const val PERSONAL_CARE = "Personal Care/Activities of Daily Living Services"

        fun defaultChecklist(): List<BookingChecklistTask> = listOf(
            BookingChecklistTask(
                title = "Position changes/ transfers",
                category = PERSONAL_CARE,
                subcategory = "Mobility assistance",
                priority = BookingTaskPriority.High,
                detailDescription = "Assist with safe transfers and position changes during the visit.",
            ),
            BookingChecklistTask(
                title = "Assistance with waking/ tucking in",
                category = PERSONAL_CARE,
                subcategory = "Personal hygiene",
                priority = BookingTaskPriority.Medium,
                detailDescription = "Support morning and evening rest routines.",
            ),
            BookingChecklistTask(
                title = "Medication Routine",
                category = PERSONAL_CARE,
                subcategory = "Medications",
                priority = BookingTaskPriority.High,
                detailDescription = "Remind and assist with scheduled medications only as directed.",
            ),
            BookingChecklistTask(
                title = "Bathing/ dressing",
                category = PERSONAL_CARE,
                subcategory = "Personal hygiene",
                priority = BookingTaskPriority.Medium,
            ),
            BookingChecklistTask(
                title = "Grooming and personal hygiene",
                category = PERSONAL_CARE,
                subcategory = "Personal hygiene",
                priority = BookingTaskPriority.Low,
            ),
        )
    }
}
