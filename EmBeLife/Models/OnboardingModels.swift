import Foundation

struct ServiceSubOption: Identifiable, Hashable {
    let id: String
    let title: String
    /// Client may add free-text notes when this item is selected.
    var allowsNotes: Bool = false
    /// Item is an "Other (describe)" entry that expects description text.
    var requiresDescription: Bool = false
}

/// Level 2 group under a top-level service category (e.g. Acupuncture under Therapeutic).
struct ServiceOptionGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let children: [ServiceSubOption]
}

enum OnboardingServiceCatalog {
    /// Flat chips for categories without Level 2 groups.
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
            .init(id: "birth-doula", title: "Birth doula"),
            .init(id: "postpartum-doula", title: "Postpartum doula (day/ night)"),
            .init(id: "midwife", title: "Midwife"),
            .init(id: "newborn-care", title: "Newborn care"),
            .init(id: "lactation", title: "Lactation/ feeding support")
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

    /// Hierarchical Level 2 → Level 3 for Therapeutic and Rehabilitation Services.
    static let optionGroups: [String: [ServiceOptionGroup]] = [
        "therapeutic": [
            .init(
                id: "acupuncture",
                title: "Acupuncture",
                children: [
                    .init(id: "acu-addiction", title: "Addiction"),
                    .init(id: "acu-anxiety", title: "Anxiety"),
                    .init(id: "acu-cancer", title: "Cancer-related symptoms and side effects"),
                    .init(id: "acu-chronic-pain", title: "Chronic pain"),
                    .init(id: "acu-depression", title: "Depression"),
                    .init(id: "acu-digestive", title: "Digestive disorders"),
                    .init(id: "acu-wellbeing", title: "General well-being"),
                    .init(id: "acu-headaches", title: "Headaches"),
                    .init(id: "acu-blood-pressure", title: "High blood pressure"),
                    .init(id: "acu-infertility", title: "Infertility"),
                    .init(id: "acu-insomnia", title: "Insomnia"),
                    .init(id: "acu-menstrual", title: "Menstrual issues"),
                    .init(id: "acu-pain", title: "Pain management"),
                    .init(id: "acu-other", title: "Other (describe)", requiresDescription: true)
                ]
            ),
            .init(
                id: "occupational",
                title: "Occupational Therapy",
                children: notesChildren(prefix: "ot", titles: [
                    "Activities of daily living (ADL)",
                    "Instrumental activities of daily living (IADL)",
                    "Home assessments (safety and accessibility)",
                    "Physical rehabilitation",
                    "Mental health support",
                    "Pain management",
                    "Cognitive support",
                    "Executive functioning skills",
                    "Work, ergonomics and school support"
                ])
            ),
            .init(
                id: "physical",
                title: "Physical Therapy",
                children: [
                    .init(id: "pt-chronic", title: "Chronic conditions management", allowsNotes: true),
                    .init(id: "pt-mobility", title: "Mobility and function improvement (general)", allowsNotes: true),
                    .init(id: "pt-pain", title: "Pain management", allowsNotes: true),
                    .init(id: "pt-pediatric", title: "Pediatric development", allowsNotes: true),
                    .init(id: "pt-rehab", title: "Rehabilitation/recovery from injury or surgery", allowsNotes: true),
                    .init(id: "pt-other", title: "Other (describe)", allowsNotes: true, requiresDescription: true)
                ]
            ),
            .init(
                id: "speech",
                title: "Speech Therapy",
                children: [
                    .init(id: "st-autism", title: "Autism spectrum disorder", allowsNotes: true),
                    .init(id: "st-cleft", title: "Cleft palate", allowsNotes: true),
                    .init(id: "st-cognitive", title: "Cognitive communication disorder", allowsNotes: true),
                    .init(id: "st-language", title: "Language disorder", allowsNotes: true),
                    .init(id: "st-articulation", title: "Speech and articulation disorder", allowsNotes: true),
                    .init(id: "st-swallowing", title: "Swallowing disorder (Dysphagia)", allowsNotes: true),
                    .init(id: "st-voice", title: "Voice disorder", allowsNotes: true),
                    .init(id: "st-other", title: "Other (describe)", allowsNotes: true, requiresDescription: true)
                ]
            )
        ]
    ]

    static func subOptions(for categoryID: String) -> [ServiceSubOption] {
        subOptions[categoryID] ?? []
    }

    static func optionGroups(for categoryID: String) -> [ServiceOptionGroup] {
        optionGroups[categoryID] ?? []
    }

    static func usesNestedOptions(_ categoryID: String) -> Bool {
        !(optionGroups[categoryID] ?? []).isEmpty
    }

    static func allLeafOptions(for categoryID: String) -> [ServiceSubOption] {
        if usesNestedOptions(categoryID) {
            return optionGroups(for: categoryID).flatMap(\.children)
        }
        return subOptions(for: categoryID)
    }

    static func option(id: String, in categoryID: String) -> ServiceSubOption? {
        allLeafOptions(for: categoryID).first { $0.id == id }
    }

    private static func notesChildren(prefix: String, titles: [String]) -> [ServiceSubOption] {
        titles.enumerated().map { index, title in
            let slug = title
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            return .init(
                id: "\(prefix)-\(slug.isEmpty ? "\(index)" : slug)",
                title: title,
                allowsNotes: true
            )
        }
    }
}
