import Foundation

enum TeamAccessRole: String, CaseIterable, Identifiable, Hashable {
    case admin
    case collaborator
    case viewer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .admin: "Admin"
        case .collaborator: "Collaborator"
        case .viewer: "Viewer"
        }
    }

    var displayTitle: String {
        switch self {
        case .admin: "Admin with Full access"
        case .collaborator, .viewer: title
        }
    }

    var canEditRole: Bool { self != .admin }

    var canExpandPermissions: Bool { self != .admin }

    var summaryBullets: [String] {
        switch self {
        case .admin:
            [
                "Admin can manage users, roles, and full workspace access.",
                "Admin can NOT be demoted by collaborators or viewers."
            ]
        case .collaborator:
            [
                "Collaborator can do what what what.",
                "Collaborator can NOT do what what what."
            ]
        case .viewer:
            [
                "Viewer can do what what what.",
                "Viewer can NOT do what what what."
            ]
        }
    }

    static var inviteChoices: [TeamAccessRole] {
        [.collaborator, .viewer]
    }
}

enum FeatureAccessKey: String, CaseIterable, Identifiable, Hashable {
    case profile
    case preference
    case booking
    case messaging
    case payment
    case notes
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile: "Profile feature access"
        case .preference: "Preference feature access"
        case .booking: "Booking/Reschedule feature access"
        case .messaging: "Messaging feature access"
        case .payment: "Payment feature access"
        case .notes: "Notes"
        case .review: "Review"
        }
    }

    var hasNestedItems: Bool {
        switch self {
        case .preference, .payment: true
        default: false
        }
    }

    static let nestedLabels = [
        "Address (create/ edit) - care recipient(s)",
        "Phone # (create/ edit) - care recipient(s)",
        "Email (create/ edit) - care recipient(s)"
    ]

    static func defaults(for role: TeamAccessRole) -> [FeatureAccessKey: Bool] {
        switch role {
        case .admin:
            Dictionary(uniqueKeysWithValues: allCases.map { ($0, true) })
        case .collaborator, .viewer:
            [
                .profile: true,
                .preference: false,
                .booking: false,
                .messaging: false,
                .payment: true,
                .notes: true,
                .review: true
            ]
        }
    }
}

struct NestedFeatureAccess: Identifiable, Hashable {
    var id: String
    var title: String
    var isEnabled: Bool
}

struct ManagedTeamUser: Identifiable, Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var role: TeamAccessRole
    var invitePending: Bool
    var permissions: [FeatureAccessKey: Bool]
    var nestedPermissions: [FeatureAccessKey: [NestedFeatureAccess]]

    var displayName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? firstName : firstName
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    static func nestedDefaults(enabled: Bool = true) -> [FeatureAccessKey: [NestedFeatureAccess]] {
        Dictionary(uniqueKeysWithValues: FeatureAccessKey.allCases.compactMap { key in
            guard key.hasNestedItems else { return nil }
            let items = FeatureAccessKey.nestedLabels.enumerated().map { index, title in
                NestedFeatureAccess(
                    id: "\(key.rawValue)-\(index)",
                    title: title,
                    isEnabled: enabled
                )
            }
            return (key, items)
        })
    }

    static let samples: [ManagedTeamUser] = [
        ManagedTeamUser(
            id: "chi",
            firstName: "Chi",
            lastName: "Roger",
            email: "chi@carebooking.app",
            role: .admin,
            invitePending: false,
            permissions: FeatureAccessKey.defaults(for: .admin),
            nestedPermissions: nestedDefaults()
        ),
        ManagedTeamUser(
            id: "john",
            firstName: "John",
            lastName: "Smith",
            email: "john@carebooking.app",
            role: .collaborator,
            invitePending: false,
            permissions: FeatureAccessKey.defaults(for: .collaborator),
            nestedPermissions: nestedDefaults()
        ),
        ManagedTeamUser(
            id: "sharee",
            firstName: "Sharee",
            lastName: "Lee",
            email: "sharee@carebooking.app",
            role: .collaborator,
            invitePending: false,
            permissions: FeatureAccessKey.defaults(for: .collaborator),
            nestedPermissions: nestedDefaults()
        ),
        ManagedTeamUser(
            id: "matt",
            firstName: "Matt",
            lastName: "Nguyen",
            email: "matt@carebooking.app",
            role: .collaborator,
            invitePending: false,
            permissions: FeatureAccessKey.defaults(for: .collaborator),
            nestedPermissions: nestedDefaults()
        ),
        ManagedTeamUser(
            id: "toby",
            firstName: "Toby",
            lastName: "Chen",
            email: "toby@carebooking.app",
            role: .viewer,
            invitePending: false,
            permissions: FeatureAccessKey.defaults(for: .viewer),
            nestedPermissions: nestedDefaults()
        )
    ]
}
