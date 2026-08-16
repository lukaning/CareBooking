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
    var selectedImageName: String? = nil

    static let all: [ServiceCategory] = [
        .init(
            id: "personal",
            title: "Personal Care/Activities of Daily Living Services",
            imageName: "svcPersonalCare",
            selectedImageName: "svcPersonalCareSelected"
        ),
        .init(
            id: "birth",
            title: "Birth, Newborn & Postpartum Services",
            imageName: "svcBirth"
        ),
        .init(
            id: "therapeutic",
            title: "Therapeutic and Rehabilitation Services",
            imageName: "svcRehab"
        ),
        .init(
            id: "nutrition",
            title: "Nutrition & Dietary Services",
            imageName: "svcDietary"
        ),
        .init(
            id: "bereavement",
            title: "Loss, Bereavement & End of Life Services",
            imageName: "svcBereavement"
        )
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
    /// Top-level service category label (e.g. Personal Care).
    var category: String
    /// Leaf / subcategory label when selected from catalog.
    var subcategory: String
    var priority: BookingTaskPriority
    var deadline: Date?
    var detailDescription: String
    var estimatedMinutes: Int?
    var attachmentNames: [String]
    var subtasks: [BookingChecklistTask]

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        subcategory: String = "",
        priority: BookingTaskPriority = .medium,
        deadline: Date? = nil,
        detailDescription: String = "",
        estimatedMinutes: Int? = nil,
        attachmentNames: [String] = [],
        subtasks: [BookingChecklistTask] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.subcategory = subcategory
        self.priority = priority
        self.deadline = deadline
        self.detailDescription = detailDescription
        self.estimatedMinutes = estimatedMinutes
        self.attachmentNames = attachmentNames
        self.subtasks = subtasks
    }

    var categoryPathLabel: String {
        if subcategory.isEmpty { return category }
        return "\(category) · \(subcategory)"
    }

    var scheduleSubtitle: String? {
        if let deadline {
            let time = deadline.formatted(date: .omitted, time: .shortened)
            if Calendar.current.isDateInToday(deadline) {
                return "Today at \(time)"
            }
            return "\(deadline.formatted(date: .abbreviated, time: .omitted)) at \(time)"
        }
        if let estimatedMinutes {
            return BookingChecklistTask.estimateLabel(for: estimatedMinutes)
        }
        return nil
    }

    static let estimateOptions = ["15 min", "30 min", "45 min", "1 hour", "1.5 hours", "2 hours"]

    static func minutes(fromEstimateLabel label: String) -> Int? {
        switch label {
        case "15 min": return 15
        case "30 min": return 30
        case "45 min": return 45
        case "1 hour": return 60
        case "1.5 hours": return 90
        case "2 hours": return 120
        default: return nil
        }
    }

    static func estimateLabel(for minutes: Int) -> String {
        switch minutes {
        case 15: return "15 min"
        case 30: return "30 min"
        case 45: return "45 min"
        case 60: return "1 hour"
        case 90: return "1.5 hours"
        case 120: return "2 hours"
        default: return "\(minutes) min"
        }
    }

    func copiedAsTemplate() -> BookingChecklistTask {
        BookingChecklistTask(
            title: title,
            category: category,
            subcategory: subcategory,
            priority: priority,
            deadline: deadline,
            detailDescription: detailDescription,
            estimatedMinutes: estimatedMinutes,
            attachmentNames: attachmentNames,
            subtasks: subtasks.map { $0.copiedAsTemplate() }
        )
    }
}

enum BookingTaskPriority: String, CaseIterable, Identifiable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
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
    /// Client star rating left after a completed visit (1…5).
    var clientReviewRating: Int?
    /// Optional free-text review left with the rating.
    var clientReviewText: String?
    /// Last reschedule proposal reason (optional).
    var rescheduleReason: String?
    /// Last reschedule note sent to the provider (optional).
    var rescheduleMessage: String?

    var hasClientReview: Bool {
        (clientReviewRating ?? 0) > 0
    }

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
        checklistTasks: [BookingChecklistTask] = Booking.defaultChecklist,
        clientReviewRating: Int? = nil,
        clientReviewText: String? = nil,
        rescheduleReason: String? = nil,
        rescheduleMessage: String? = nil
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
        self.clientReviewRating = clientReviewRating
        self.clientReviewText = clientReviewText
        self.rescheduleReason = rescheduleReason
        self.rescheduleMessage = rescheduleMessage
    }

    static let defaultChecklist: [BookingChecklistTask] = [
        BookingChecklistTask(
            title: "Position changes/ transfers",
            category: "Personal Care/Activities of Daily Living Services",
            subcategory: "Mobility assistance",
            priority: .high,
            detailDescription: "Assist with safe transfers and position changes during the visit."
        ),
        BookingChecklistTask(
            title: "Assistance with waking/ tucking in",
            category: "Personal Care/Activities of Daily Living Services",
            subcategory: "Personal hygiene",
            priority: .medium,
            detailDescription: "Support morning and evening rest routines."
        ),
        BookingChecklistTask(
            title: "Medication Routine",
            category: "Personal Care/Activities of Daily Living Services",
            subcategory: "Medications",
            priority: .high,
            detailDescription: "Remind and assist with scheduled medications only as directed."
        ),
        BookingChecklistTask(
            title: "Bathing/ dressing",
            category: "Personal Care/Activities of Daily Living Services",
            subcategory: "Personal hygiene",
            priority: .medium
        ),
        BookingChecklistTask(
            title: "Grooming and personal hygiene",
            category: "Personal Care/Activities of Daily Living Services",
            subcategory: "Personal hygiene",
            priority: .low
        )
    ]
}
