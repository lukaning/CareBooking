import Foundation

struct ServiceSubOption: Identifiable, Hashable {
    let id: String
    let title: String
}

enum OnboardingServiceCatalog {
    static let subOptions: [String: [ServiceSubOption]] = [
        "personal": [
            .init(id: "meals", title: "Meals & Groceries"),
            .init(id: "medications", title: "Medications"),
            .init(id: "hygiene", title: "Personal hygiene"),
            .init(id: "mobility", title: "Mobility assistance"),
            .init(id: "housekeeping", title: "Light housekeeping"),
            .init(id: "transport", title: "Transportation/ medical and other appointments"),
            .init(id: "errands", title: "Running errands"),
            .init(id: "companionship", title: "Companionship/ emotional support"),
            .init(id: "pet-care", title: "Pet care (feed/ walk)")
        ],
        "birth": [
            .init(id: "birth-ed", title: "Birth education"),
            .init(id: "labor", title: "Labor and birth support"),
            .init(id: "lactation", title: "Lactation and feeding support"),
            .init(id: "recovery", title: "Postpartum recovery care"),
            .init(id: "newborn", title: "Newborn/ infant"),
            .init(id: "parenting", title: "Parenting education"),
            .init(id: "multiples", title: "Multiples education")
        ],
        "therapeutic": [
            .init(id: "occupational", title: "Occupational therapy"),
            .init(id: "physical", title: "Physical therapy"),
            .init(id: "speech", title: "Speech therapy"),
            .init(id: "pain", title: "Pain management"),
            .init(id: "wellness", title: "General wellness")
        ],
        "nutrition": [
            .init(id: "meal-plan", title: "Meal planning"),
            .init(id: "nutrition", title: "Nutrition counseling"),
            .init(id: "dietary-mgmt", title: "Dietary management")
        ],
        "bereavement": [
            .init(id: "grief", title: "Grief counseling"),
            .init(id: "memorial", title: "Memorial planning"),
            .init(id: "family", title: "Family support"),
            .init(id: "end-of-life", title: "End of life support")
        ]
    ]

    static func subOptions(for categoryID: String) -> [ServiceSubOption] {
        subOptions[categoryID] ?? []
    }
}
