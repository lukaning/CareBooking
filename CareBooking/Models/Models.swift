import Foundation

struct Provider: Identifiable, Hashable {
    let id: String
    let name: String
    let title: String
    let ratePerHour: Int
    let rating: Double
    let reviewCount: Int
    let bio: String
    let specialties: String
    let bookingCount: Int
    let imageName: String

    static let samples: [Provider] = [
        Provider(
            id: "eric",
            name: "Eric Acmen",
            title: "Personal Care Aide",
            ratePerHour: 25,
            rating: 4.8,
            reviewCount: 5,
            bio: "I believe that every child is unique, and I tailor my care to meet the individual needs and personalities of each child in my care.",
            specialties: "Specialties: meal prep, light housekeeping, running errands",
            bookingCount: 56,
            imageName: "providerAvatar"
        ),
        Provider(
            id: "maya",
            name: "Maya Chen",
            title: "Postpartum Doula",
            ratePerHour: 40,
            rating: 4.9,
            reviewCount: 18,
            bio: "I support families through the early postpartum weeks with feeding guidance, recovery care, and calm companionship.",
            specialties: "Specialties: lactation support, newborn care, overnight support",
            bookingCount: 112,
            imageName: "providerAvatar"
        ),
        Provider(
            id: "jordan",
            name: "Jordan Lee",
            title: "Companion Care",
            ratePerHour: 28,
            rating: 4.7,
            reviewCount: 9,
            bio: "I focus on meaningful conversation, light activity, and helping clients stay connected to daily routines.",
            specialties: "Specialties: companionship, transportation, grocery help",
            bookingCount: 41,
            imageName: "providerAvatar"
        )
    ]
}

struct ServiceCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let imageName: String

    static let all: [ServiceCategory] = [
        .init(id: "personal", title: "Personal Care/ Activities of Daily Living", imageName: "svcPersonalCare"),
        .init(id: "birth", title: "Birth/ Postpartum Services", imageName: "svcBirth"),
        .init(id: "acupuncture", title: "Acupuncture", imageName: "svcAcupuncture"),
        .init(id: "bereavement", title: "Bereavement/ Loss", imageName: "svcBereavement"),
        .init(id: "dietary", title: "Dietary/ Nutrition Counseling & Services", imageName: "svcDietary"),
        .init(id: "rehab", title: "Rehabilitative Therapies (Occupational, Physical, Speech)", imageName: "svcRehab"),
        .init(id: "special", title: "Special Needs Assistance/ Specialized Care", imageName: "svcSpecial")
    ]
}

enum BookingStatus: String, CaseIterable, Identifiable {
    case requested
    case booked
    case completed

    var id: String { rawValue }

    var tab: BookingTab {
        switch self {
        case .requested: .requested
        case .booked: .booked
        case .completed: .completed
        }
    }
}

struct BookingChecklistTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: String

    init(id: UUID = UUID(), title: String, category: String) {
        self.id = id
        self.title = title
        self.category = category
    }
}

struct Booking: Identifiable, Hashable {
    let id: UUID
    let provider: Provider
    var date: Date
    var startTime: Date
    var durationMinutes: Int
    var status: BookingStatus
    var serviceProvidedTo: String
    var title: String
    var taskDescription: String
    var location: String
    var dateCreated: Date
    var checklistTasks: [BookingChecklistTask]

    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var timeRangeLabel: String {
        let start = startTime.formatted(date: .omitted, time: .shortened)
        let end = endTime.formatted(date: .omitted, time: .shortened)
        return "\(start) - \(end)"
    }

    var timeRangeWithDurationLabel: String {
        let hours = durationMinutes / 60
        let duration = hours == 1 ? "1 Hour" : "\(hours) Hours"
        return "\(timeRangeLabel) (\(duration))"
    }

    init(
        id: UUID = UUID(),
        provider: Provider,
        date: Date,
        startTime: Date,
        durationMinutes: Int,
        status: BookingStatus = .requested,
        serviceProvidedTo: String = "",
        title: String = "Spear Street Household Task",
        taskDescription: String = "This task is aimed at taking care of daily chores and some lightweight cooking and taking care of this and that.",
        location: String = "San Francisco, Detailed Location",
        dateCreated: Date = .now,
        checklistTasks: [BookingChecklistTask] = Booking.defaultChecklist
    ) {
        self.id = id
        self.provider = provider
        self.date = date
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.status = status
        self.serviceProvidedTo = serviceProvidedTo
        self.title = title
        self.taskDescription = taskDescription
        self.location = location
        self.dateCreated = dateCreated
        self.checklistTasks = checklistTasks
    }

    static let defaultChecklist: [BookingChecklistTask] = [
        BookingChecklistTask(title: "Position changes/ transfers", category: "Category 1"),
        BookingChecklistTask(title: "Assistance with waking/ tucking in", category: "Category 1"),
        BookingChecklistTask(title: "Medication Routine", category: "Category 2"),
        BookingChecklistTask(title: "Bathing/ dressing", category: "Category 2"),
        BookingChecklistTask(title: "Grooming and personal hygiene", category: "Category 1")
    ]
}
