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
    var locationChoice: LocationChoice?
    var customLocation = ""

    var profile = UserProfile()
    var bookings: [Booking] = []
    var providers: [Provider] = Provider.samples

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
                profile.address = customLocation
            case .none:
                break
            }
        }
        if profile.servicesRequestedFor.isEmpty {
            let titles = ServiceCategory.all
                .filter { selectedServiceIDs.contains($0.id) }
                .map(\.title)
            profile.servicesRequestedFor = titles.prefix(3).joined(separator: ", ")
        }
        flow = .main
    }

    func signOut() {
        isSignedIn = false
        hasCompletedOnboarding = false
        selectedRole = nil
        selectedServiceIDs = []
        locationChoice = nil
        profile = UserProfile()
        bookings = []
        flow = .auth
    }

    func addBooking(_ booking: Booking) {
        bookings.insert(booking, at: 0)
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
            addBooking(
                Booking(
                    provider: eric,
                    date: date,
                    startTime: start,
                    durationMinutes: 120,
                    status: .requested,
                    serviceProvidedTo: next.familyMembers.first?.displayName ?? "S. Roger"
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
