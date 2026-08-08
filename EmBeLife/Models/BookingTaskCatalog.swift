import Foundation

/// Care task catalog for the booking “Select category” step (Add Task design).
struct BookingTaskOption: Identifiable, Hashable {
    let categoryID: String
    let categoryTitle: String
    let title: String

    var id: String { "\(categoryID)|\(title)" }
}

struct BookingTaskCategoryGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let tasks: [String]

    var options: [BookingTaskOption] {
        tasks.map {
            BookingTaskOption(categoryID: id, categoryTitle: title, title: $0)
        }
    }
}

enum BookingTaskCatalog {
    static let groups: [BookingTaskCategoryGroup] = [
        .init(
            id: "companionship",
            title: "Companionship/ emotional support",
            tasks: ["Companionship/ emotional support"]
        ),
        .init(
            id: "meals",
            title: "Meals",
            tasks: [
                "Meal prep/ planning",
                "Grocery shopping/ assistance",
                "Clean/ tidy after meals"
            ]
        ),
        .init(
            id: "housekeeping",
            title: "Light housekeeping",
            tasks: [
                "Wash/ put away dishes",
                "Laundry",
                "Linen changes",
                "Tidy areas",
                "Light vacuuming",
                "Dusting"
            ]
        ),
        .init(
            id: "medications",
            title: "Medications",
            tasks: [
                "Organize",
                "Reminders",
                "Monitor",
                "Pick up medications from pharmacy"
            ]
        ),
        .init(
            id: "mobility",
            title: "Mobility assistance",
            tasks: [
                "Light exercise",
                "Walking",
                "Exercise/ therapy programs assistance",
                "Position changes",
                "Using assistive devices - e.g. crutches, walkers, wheelchairs"
            ]
        ),
        .init(
            id: "personal",
            title: "Personal care",
            tasks: [
                "Bathing",
                "Dressing",
                "Grooming",
                "Personal hygiene/ Toileting"
            ]
        ),
        .init(
            id: "transport",
            title: "Transportation/ errand assistance",
            tasks: [
                "Drive to/ from appointments",
                "Run errands"
            ]
        )
    ]

    static var allOptions: [BookingTaskOption] {
        groups.flatMap(\.options)
    }

    /// Suggested checklist rows derived from selected category chips.
    static func suggestedChecklist(from selected: [BookingTaskOption]) -> [BookingChecklistTask] {
        selected.map { option in
            BookingChecklistTask(
                title: option.title,
                category: option.categoryTitle,
                subcategory: option.title,
                priority: .medium
            )
        }
    }
}
