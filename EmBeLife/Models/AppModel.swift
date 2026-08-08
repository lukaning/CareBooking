import Foundation
import SwiftUI

enum AppFlow: Hashable {
    case auth
    case onboarding
    case main
}

enum UserRole: String, CaseIterable, Identifiable {
    case client
    case provider

    var id: String { rawValue }
}

enum LocationChoice: String, CaseIterable, Identifiable {
    case current
    case custom

    var id: String { rawValue }
}

enum BookingTab: String, CaseIterable, Identifiable {
    case requested = "Requested"
    case booked = "Booked"
    case completed = "Completed"

    var id: String { rawValue }

    /// Short label used in filled profile segmented control
    var shortTitle: String {
        switch self {
        case .requested: "Request"
        case .booked: "Booked"
        case .completed: "Completed"
        }
    }
}

@Observable
final class AppModel {
    var flow: AppFlow = .onboarding
    var isSignedIn = false
    var hasCompletedOnboarding = false
    /// When true, onboarding skips the welcome step (e.g. after sign-in/sign-up).
    var skipWelcomeStep = false

    var userName = ""
    var userEmail = ""
    var preferredLanguage = "English"
    var selectedRole: UserRole?
    var selectedServiceIDs: Set<String> = []
    /// Flat chip selections, or Level 3 leaf selections for nested categories.
    var selectedSubServiceIDs: [String: Set<String>] = [:]
    /// Level 2 group selections for nested categories (e.g. Acupuncture under Therapeutic).
    var selectedServiceGroupIDs: [String: Set<String>] = [:]
    /// Optional notes / descriptions keyed by Level 3 option id.
    var serviceOptionNotes: [String: String] = [:]
    var locationChoice: LocationChoice?
    var customLocation = ""
    var customAddress = ""
    var customZipcode = ""
    var searchRadiusMiles: Double = 25
    /// Confirmed via the in-panel Confirm button (current or custom).
    var locationConfirmed = false
    var resolvedCurrentAddress = ""

    var profile = UserProfile()
    var bookings: [Booking] = []
    var providers: [Provider] = Provider.samples
    var managedUsers: [ManagedTeamUser] = ManagedTeamUser.samples
    /// All provider reviews keyed for Rate & Review screens.
    var providerReviews: [ProviderReview] = ProviderReview.samples(for: "eric")
        + ProviderReview.samples(for: "maya")
        + ProviderReview.samples(for: "jordan")

    func reviews(for providerID: String) -> [ProviderReview] {
        providerReviews.filter { $0.providerID == providerID }
    }

    func addProviderReview(providerID: String, rating: Int, body: String, authorName: String) {
        let review = ProviderReview(
            providerID: providerID,
            authorName: authorName,
            avatarRed: 0.35,
            avatarGreen: 0.55,
            avatarBlue: 0.95,
            rating: max(1, min(5, rating)),
            body: body,
            relativeTime: "just now"
        )
        providerReviews.insert(review, at: 0)
        if let index = providers.firstIndex(where: { $0.id == providerID }) {
            // Soft-update displayed count; keep average stable for MVP sample data.
            let p = providers[index]
            providers[index] = Provider(
                id: p.id,
                name: p.name,
                title: p.title,
                ratePerHour: p.ratePerHour,
                rating: p.rating,
                reviewCount: p.reviewCount + 1,
                bio: p.bio,
                specialties: p.specialties,
                bookingCount: p.bookingCount,
                imageName: p.imageName
            )
        }
    }

    func toggleReviewLike(id: UUID) {
        guard let index = providerReviews.firstIndex(where: { $0.id == id }) else { return }
        providerReviews[index].liked.toggle()
    }

    func submitBookingReview(bookingID: UUID, rating: Int, text: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        let clipped = max(1, min(5, rating))
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        bookings[index].clientReviewRating = clipped
        bookings[index].clientReviewText = trimmed
        let providerID = bookings[index].provider.id
        addProviderReview(
            providerID: providerID,
            rating: clipped,
            body: trimmed,
            authorName: userName.isEmpty ? "You" : userName
        )
    }

    func completeSignIn(email: String, name: String = "") {
        userEmail = email
        if !name.isEmpty { userName = name }
        isSignedIn = true
        syncProfileBasics()
        if hasCompletedOnboarding {
            flow = .main
        } else {
            skipWelcomeStep = true
            flow = .onboarding
        }
    }

    func completeSignUp(name: String, email: String) {
        userName = name
        userEmail = email
        isSignedIn = true
        syncProfileBasics()
        skipWelcomeStep = true
        flow = .onboarding
    }

    func showAuth() {
        flow = .auth
    }

    func showWelcome() {
        skipWelcomeStep = false
        flow = .onboarding
    }

    func finishOnboarding() {
        hasCompletedOnboarding = true
        if profile.address.isEmpty {
            switch locationChoice {
            case .current:
                profile.address = resolvedCurrentAddress.isEmpty
                    ? "Current location"
                    : resolvedCurrentAddress
            case .custom:
                if !customAddress.isEmpty {
                    profile.address = [customAddress, customZipcode]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                } else {
                    profile.address = customLocation
                }
            case .none:
                break
            }
        }
        if profile.servicesRequestedFor.isEmpty {
            let titles = ServiceCategory.all
                .filter { selectedServiceIDs.contains($0.id) }
                .map(\.title)
            profile.servicesRequestedFor = titles.isEmpty
                ? selectedSubServiceLabels.joined(separator: ", ")
                : titles.prefix(3).joined(separator: ", ")
        }
        flow = .main
    }

    var selectedSubServiceLabels: [String] {
        selectedSubServiceIDs.flatMap { categoryID, ids in
            OnboardingServiceCatalog.allLeafOptions(for: categoryID)
                .filter { ids.contains($0.id) }
                .map(\.title)
        }
    }

    func clearServiceSelections(for categoryID: String) {
        let leafIDs = selectedSubServiceIDs[categoryID] ?? []
        for leafID in leafIDs {
            serviceOptionNotes.removeValue(forKey: leafID)
        }
        selectedSubServiceIDs[categoryID] = []
        selectedServiceGroupIDs[categoryID] = []
    }

    func signOut() {
        isSignedIn = false
        hasCompletedOnboarding = false
        selectedRole = nil
        selectedServiceIDs = []
        selectedSubServiceIDs = [:]
        selectedServiceGroupIDs = [:]
        serviceOptionNotes = [:]
        locationChoice = nil
        customLocation = ""
        customAddress = ""
        customZipcode = ""
        locationConfirmed = false
        resolvedCurrentAddress = ""
        profile = UserProfile()
        bookings = []
        skipWelcomeStep = false
        flow = .onboarding
    }

    func addBooking(_ booking: Booking) {
        bookings.insert(booking, at: 0)
    }

    func updateBooking(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index] = booking
    }

    /// Append care tasks to a Requested or Booked appointment checklist.
    func appendChecklistTasks(to bookingID: UUID, tasks: [BookingChecklistTask]) {
        guard !tasks.isEmpty,
              let index = bookings.firstIndex(where: { $0.id == bookingID })
        else { return }
        guard bookings[index].status != .completed else { return }
        bookings[index].checklistTasks.append(contentsOf: tasks)
    }

    func rescheduleBooking(
        id: UUID,
        date: Date,
        startTime: Date,
        reason: String = "",
        message: String = ""
    ) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[index].date = date
        bookings[index].startTime = startTime
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        bookings[index].rescheduleReason = trimmedReason.isEmpty ? nil : trimmedReason
        bookings[index].rescheduleMessage = trimmedMessage.isEmpty ? nil : trimmedMessage
    }

    func cancelBooking(id: UUID) {
        bookings.removeAll { $0.id == id }
    }

    func booking(id: UUID) -> Booking? {
        bookings.first { $0.id == id }
    }

    /// Seeds sample Requested / Booked / Completed items when the list is empty.
    func seedBookingsIfNeeded() {
        guard bookings.isEmpty else { return }
        guard providers.count >= 2 else { return }

        let calendar = Calendar.current
        let today = Date()

        func dayOffset(_ days: Int, hour: Int, minute: Int = 0) -> (date: Date, start: Date) {
            let date = calendar.date(byAdding: .day, value: days, to: today) ?? today
            let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
            return (date, start)
        }

        let booked = dayOffset(3, hour: 10)
        let requested = dayOffset(7, hour: 15)
        let completed = dayOffset(-5, hour: 14)

        bookings = [
            Booking(
                provider: providers[0],
                date: booked.date,
                startTime: booked.start,
                durationMinutes: 120,
                status: .booked,
                serviceProvidedTo: "Parent"
            ),
            Booking(
                provider: providers[0],
                date: requested.date,
                startTime: requested.start,
                durationMinutes: 120,
                status: .requested,
                serviceProvidedTo: "S. Roger"
            ),
            Booking(
                provider: providers[0],
                date: completed.date,
                startTime: completed.start,
                durationMinutes: 120,
                status: .completed,
                serviceProvidedTo: "S. Roger"
            )
        ]
    }

    func inviteManagedUser(
        firstName: String,
        lastName: String,
        email: String,
        role: TeamAccessRole,
        permissions: [FeatureAccessKey: Bool],
        nestedPermissions: [FeatureAccessKey: [NestedFeatureAccess]]
    ) {
        let user = ManagedTeamUser(
            id: UUID().uuidString,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            invitePending: true,
            permissions: permissions,
            nestedPermissions: nestedPermissions
        )
        managedUsers.append(user)
    }

    func updateManagedUserRole(id: String, role: TeamAccessRole) {
        guard let index = managedUsers.firstIndex(where: { $0.id == id }) else { return }
        var user = managedUsers[index]
        user.role = role
        user.permissions = FeatureAccessKey.defaults(for: role)
        if role == .admin {
            user.invitePending = false
        }
        managedUsers[index] = user
    }

    func updateManagedUserPermission(id: String, key: FeatureAccessKey, isEnabled: Bool) {
        guard let index = managedUsers.firstIndex(where: { $0.id == id }) else { return }
        var user = managedUsers[index]
        user.permissions[key] = isEnabled
        managedUsers[index] = user
    }

    func updateManagedNestedPermission(id: String, key: FeatureAccessKey, nestedID: String, isEnabled: Bool) {
        guard let index = managedUsers.firstIndex(where: { $0.id == id }) else { return }
        var user = managedUsers[index]
        guard var items = user.nestedPermissions[key],
              let nestedIndex = items.firstIndex(where: { $0.id == nestedID })
        else { return }
        items[nestedIndex].isEnabled = isEnabled
        user.nestedPermissions[key] = items
        managedUsers[index] = user
    }

    func updateManagedUserPermissions(
        id: String,
        permissions: [FeatureAccessKey: Bool],
        nestedPermissions: [FeatureAccessKey: [NestedFeatureAccess]]
    ) {
        guard let index = managedUsers.firstIndex(where: { $0.id == id }) else { return }
        var user = managedUsers[index]
        user.permissions = permissions
        user.nestedPermissions = nestedPermissions
        managedUsers[index] = user
    }

    func publishProfile(_ draft: UserProfile) {
        var next = draft
        next.hasUploadedPhoto = true
        next.isPublished = true
        if next.servicesRequestedFor.isEmpty {
            next.servicesRequestedFor = "mother, father, aunt, child"
        }
        if next.address == "San Francisco, CA, United States" || next.address.isEmpty == false {
            // Keep address as entered; design final also shows street in Seattle — use draft address
        }
        profile = next
        userName = next.displayFirstLast
        userEmail = next.email.isEmpty ? userEmail : next.email

        if bookings.isEmpty, let eric = providers.first {
            let calendar = Calendar.current
            let date = calendar.date(from: DateComponents(year: 2025, month: 1, day: 25)) ?? .now
            let start = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date
            let created = calendar.date(from: DateComponents(year: 2024, month: 11, day: 10)) ?? .now
            addBooking(
                Booking(
                    provider: eric,
                    date: date,
                    startTime: start,
                    durationMinutes: 120,
                    status: .requested,
                    serviceProvidedTo: "Katie M's Parent: Mike",
                    dateCreated: created
                )
            )
        }
    }

    private func syncProfileBasics() {
        if profile.firstName.isEmpty, !userName.isEmpty {
            let parts = userName.split(separator: " ").map(String.init)
            profile.firstName = parts.first ?? ""
            if parts.count > 1 {
                profile.lastName = parts.dropFirst().joined(separator: " ")
            }
        }
        if profile.email.isEmpty {
            profile.email = userEmail
        }
    }
}
