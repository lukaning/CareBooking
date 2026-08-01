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
    var flow: AppFlow = .auth
    var isSignedIn = false
    var hasCompletedOnboarding = false

    var userName = ""
    var userEmail = ""
    var preferredLanguage = "English"
    var selectedRole: UserRole?
    var selectedServiceIDs: Set<String> = []
    var selectedSubServiceIDs: [String: Set<String>] = [:]
    var locationChoice: LocationChoice?
    var customLocation = ""
    var customAddress = ""
    var customZipcode = ""
    var searchRadiusMiles: Double = 25
    var customLocationConfirmed = false

    var profile = UserProfile()
    var bookings: [Booking] = []
    var providers: [Provider] = Provider.samples
    var managedUsers: [ManagedTeamUser] = ManagedTeamUser.samples

    func completeSignIn(email: String, name: String = "") {
        userEmail = email
        if !name.isEmpty { userName = name }
        isSignedIn = true
        syncProfileBasics()
        flow = hasCompletedOnboarding ? .main : .onboarding
    }

    func completeSignUp(name: String, email: String) {
        userName = name
        userEmail = email
        isSignedIn = true
        syncProfileBasics()
        flow = .onboarding
    }

    func finishOnboarding() {
        hasCompletedOnboarding = true
        if profile.address.isEmpty {
            switch locationChoice {
            case .current:
                profile.address = "Current location"
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
            OnboardingServiceCatalog.subOptions(for: categoryID)
                .filter { ids.contains($0.id) }
                .map(\.title)
        }
    }

    func signOut() {
        isSignedIn = false
        hasCompletedOnboarding = false
        selectedRole = nil
        selectedServiceIDs = []
        selectedSubServiceIDs = [:]
        locationChoice = nil
        customLocation = ""
        customAddress = ""
        customZipcode = ""
        customLocationConfirmed = false
        profile = UserProfile()
        bookings = []
        flow = .auth
    }

    func addBooking(_ booking: Booking) {
        bookings.insert(booking, at: 0)
    }

    func updateBooking(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index] = booking
    }

    func rescheduleBooking(id: UUID, date: Date, startTime: Date) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[index].date = date
        bookings[index].startTime = startTime
    }

    func cancelBooking(id: UUID) {
        bookings.removeAll { $0.id == id }
    }

    func booking(id: UUID) -> Booking? {
        bookings.first { $0.id == id }
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
