import Foundation
import SwiftUI

enum MemberAvatarStyle: String, CaseIterable, Hashable {
    case pink, orange, purple, green, blue

    var color: Color {
        switch self {
        case .pink: Color(red: 0.98, green: 0.70, blue: 0.78)
        case .orange: Color(red: 1.0, green: 0.72, blue: 0.45)
        case .purple: Color(red: 0.72, green: 0.62, blue: 0.95)
        case .green: Color(red: 0.55, green: 0.82, blue: 0.65)
        case .blue: Color(red: 0.55, green: 0.72, blue: 0.95)
        }
    }

    static func next(after count: Int) -> MemberAvatarStyle {
        allCases[count % allCases.count]
    }
}

struct FamilyMember: Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var preferredServices: [String]
    var preferredTimes: [String]
    var avatarStyle: MemberAvatarStyle

    var displayName: String {
        if lastName.isEmpty { return firstName }
        if firstName.contains(".") {
            return "\(firstName). \(lastName)".replacingOccurrences(of: "..", with: ".")
        }
        let letter = firstName.first.map(String.init) ?? "?"
        return "\(letter). \(lastName)"
    }

    var monogram: String {
        firstName.first.map(String.init) ?? "?"
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        preferredServices: [String] = [],
        preferredTimes: [String] = [],
        avatarStyle: MemberAvatarStyle = .pink
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.preferredServices = preferredServices
        self.preferredTimes = preferredTimes
        self.avatarStyle = avatarStyle
    }
}

struct UserProfile: Hashable {
    var firstName = ""
    var middleName = ""
    var lastName = ""
    var address = ""
    var email = ""
    var mobile = ""
    var languages: [String] = []
    var familyMembers: [FamilyMember] = []
    var hasUploadedPhoto = false
    var rating = 4.8
    var reviewCount = 5
    var roleLabel = "Customer"
    var accountType = "Owner Account"
    var servicesRequestedFor = ""
    var isPublished = false

    var fullName: String {
        [firstName, middleName, lastName]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " ")
    }

    var displayFirstLast: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var hasMinimumContact: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !address.isEmpty
    }

    var isFilled: Bool {
        isPublished && hasMinimumContact
    }
}

extension FamilyMember {
    static let preferredServiceOptions: [String] = [
        "Personal care/ hygiene",
        "Mobility assistance",
        "House keeping",
        "Companionship",
        "Meal prep",
        "Transportation",
        "Light housekeeping"
    ]

    static let preferredTimeOptions: [String] = [
        "8am – 10am",
        "10am – 1pm",
        "1pm – 3pm",
        "3pm – 6pm",
        "6pm – 8pm"
    ]

    static let samples: [FamilyMember] = [
        FamilyMember(
            firstName: "S",
            lastName: "Roger",
            preferredServices: ["Personal care/ hygiene", "Mobility assistance", "House keeping"],
            preferredTimes: ["8am – 10am", "3pm – 6pm"],
            avatarStyle: .pink
        ),
        FamilyMember(
            firstName: "J.M.S",
            lastName: "Roger",
            preferredServices: ["Companionship", "Meal prep"],
            preferredTimes: ["9am – 12pm"],
            avatarStyle: .orange
        ),
        FamilyMember(
            firstName: "J",
            lastName: "Roger",
            preferredServices: ["Transportation"],
            preferredTimes: ["1pm – 3pm"],
            avatarStyle: .purple
        ),
        FamilyMember(
            firstName: "M",
            lastName: "Roger",
            preferredServices: ["Light housekeeping"],
            preferredTimes: ["10am – 1pm"],
            avatarStyle: .green
        )
    ]

    static let existingAccounts: [FamilyMember] = samples
}
