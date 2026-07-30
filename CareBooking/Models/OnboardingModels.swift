import Foundation

struct ServiceSubOption: Identifiable, Hashable {
    let id: String
    let title: String
}

enum OnboardingServiceCatalog {
    static let subOptions: [String: [ServiceSubOption]] = [
        "personal": [
            .init(id: "meals", title: "Meals & Groceries"),
            .init(id: "medication", title: "Medication assistance"),
            .init(id: "hygiene", title: "Personal care/ hygiene"),
            .init(id: "mobility", title: "Mobility assistance"),
            .init(id: "housekeeping", title: "Light housekeeping"),
            .init(id: "transport", title: "Transportation/ appointments"),
            .init(id: "errands", title: "Errands")
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
        "acupuncture": [
            .init(id: "pain", title: "Pain management"),
            .init(id: "wellness", title: "General wellness"),
            .init(id: "fertility", title: "Fertility support")
        ],
        "bereavement": [
            .init(id: "grief", title: "Grief counseling"),
            .init(id: "memorial", title: "Memorial planning"),
            .init(id: "family", title: "Family support")
        ],
        "dietary": [
            .init(id: "meal-plan", title: "Meal planning"),
            .init(id: "nutrition", title: "Nutrition counseling"),
            .init(id: "dietary-mgmt", title: "Dietary management")
        ],
        "rehab": [
            .init(id: "occupational", title: "Occupational therapy"),
            .init(id: "physical", title: "Physical therapy"),
            .init(id: "speech", title: "Speech therapy")
        ],
        "special": [
            .init(id: "special-needs", title: "Special needs support"),
            .init(id: "developmental", title: "Developmental assistance"),
            .init(id: "behavioral", title: "Behavioral support")
        ]
    ]

    static func subOptions(for categoryID: String) -> [ServiceSubOption] {
        subOptions[categoryID] ?? []
    }
}
