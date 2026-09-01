package com.embelife.app.model

data class ServiceSubOption(
    val id: String,
    val title: String,
    /** Client may add free-text notes when this item is selected. */
    val allowsNotes: Boolean = false,
    /** Item is an "Other (describe)" entry that expects description text. */
    val requiresDescription: Boolean = false,
)

/** Level 2 group under a top-level service category (e.g. Acupuncture under Therapeutic). */
data class ServiceOptionGroup(
    val id: String,
    val title: String,
    val children: List<ServiceSubOption>,
)

object OnboardingServiceCatalog {

    /** Flat chips for categories without Level 2 groups. */
    private val subOptions: Map<String, List<ServiceSubOption>> = mapOf(
        "personal" to listOf(
            ServiceSubOption("meals", "Meals & Groceries"),
            ServiceSubOption("medications", "Medications"),
            ServiceSubOption("hygiene", "Personal hygiene"),
            ServiceSubOption("mobility", "Mobility assistance"),
            ServiceSubOption("housekeeping", "Light housekeeping"),
            ServiceSubOption("transport", "Transportation/ medical and other appointments"),
            ServiceSubOption("errands", "Running errands"),
            ServiceSubOption("companionship", "Companionship/ emotional support"),
            ServiceSubOption("pet-care", "Pet care (feed/ walk)"),
        ),
        "birth" to listOf(
            ServiceSubOption("birth-doula", "Birth doula"),
            ServiceSubOption("postpartum-doula", "Postpartum doula (day/ night)"),
            ServiceSubOption("midwife", "Midwife"),
            ServiceSubOption("newborn-care", "Newborn care"),
            ServiceSubOption("lactation", "Lactation/ feeding support"),
        ),
        "nutrition" to listOf(
            ServiceSubOption("meal-plan", "Meal planning"),
            ServiceSubOption("nutrition", "Nutrition counseling"),
            ServiceSubOption("dietary-mgmt", "Dietary management"),
        ),
        "bereavement" to listOf(
            ServiceSubOption("grief", "Grief counseling"),
            ServiceSubOption("memorial", "Memorial planning"),
            ServiceSubOption("family", "Family support"),
            ServiceSubOption("end-of-life", "End of life support"),
        ),
    )

    /** Hierarchical Level 2 → Level 3 for Therapeutic and Rehabilitation Services. */
    private val optionGroups: Map<String, List<ServiceOptionGroup>> = mapOf(
        "therapeutic" to listOf(
            ServiceOptionGroup(
                id = "acupuncture",
                title = "Acupuncture",
                children = listOf(
                    ServiceSubOption("acu-addiction", "Addiction"),
                    ServiceSubOption("acu-anxiety", "Anxiety"),
                    ServiceSubOption("acu-cancer", "Cancer-related symptoms and side effects"),
                    ServiceSubOption("acu-chronic-pain", "Chronic pain"),
                    ServiceSubOption("acu-depression", "Depression"),
                    ServiceSubOption("acu-digestive", "Digestive disorders"),
                    ServiceSubOption("acu-wellbeing", "General well-being"),
                    ServiceSubOption("acu-headaches", "Headaches"),
                    ServiceSubOption("acu-blood-pressure", "High blood pressure"),
                    ServiceSubOption("acu-infertility", "Infertility"),
                    ServiceSubOption("acu-insomnia", "Insomnia"),
                    ServiceSubOption("acu-menstrual", "Menstrual issues"),
                    ServiceSubOption("acu-pain", "Pain management"),
                    ServiceSubOption("acu-other", "Other (describe)", requiresDescription = true),
                ),
            ),
            ServiceOptionGroup(
                id = "occupational",
                title = "Occupational Therapy",
                children = notesChildren(
                    prefix = "ot",
                    titles = listOf(
                        "Activities of daily living (ADL)",
                        "Instrumental activities of daily living (IADL)",
                        "Home assessments (safety and accessibility)",
                        "Physical rehabilitation",
                        "Mental health support",
                        "Pain management",
                        "Cognitive support",
                        "Executive functioning skills",
                        "Work, ergonomics and school support",
                    ),
                ),
            ),
            ServiceOptionGroup(
                id = "physical",
                title = "Physical Therapy",
                children = listOf(
                    ServiceSubOption("pt-chronic", "Chronic conditions management", allowsNotes = true),
                    ServiceSubOption("pt-mobility", "Mobility and function improvement (general)", allowsNotes = true),
                    ServiceSubOption("pt-pain", "Pain management", allowsNotes = true),
                    ServiceSubOption("pt-pediatric", "Pediatric development", allowsNotes = true),
                    ServiceSubOption("pt-rehab", "Rehabilitation/recovery from injury or surgery", allowsNotes = true),
                    ServiceSubOption("pt-other", "Other (describe)", allowsNotes = true, requiresDescription = true),
                ),
            ),
            ServiceOptionGroup(
                id = "speech",
                title = "Speech Therapy",
                children = listOf(
                    ServiceSubOption("st-autism", "Autism spectrum disorder", allowsNotes = true),
                    ServiceSubOption("st-cleft", "Cleft palate", allowsNotes = true),
                    ServiceSubOption("st-cognitive", "Cognitive communication disorder", allowsNotes = true),
                    ServiceSubOption("st-language", "Language disorder", allowsNotes = true),
                    ServiceSubOption("st-articulation", "Speech and articulation disorder", allowsNotes = true),
                    ServiceSubOption("st-swallowing", "Swallowing disorder (Dysphagia)", allowsNotes = true),
                    ServiceSubOption("st-voice", "Voice disorder", allowsNotes = true),
                    ServiceSubOption("st-other", "Other (describe)", allowsNotes = true, requiresDescription = true),
                ),
            ),
        ),
    )

    fun subOptions(categoryID: String): List<ServiceSubOption> = subOptions[categoryID] ?: emptyList()

    fun optionGroups(categoryID: String): List<ServiceOptionGroup> = optionGroups[categoryID] ?: emptyList()

    fun usesNestedOptions(categoryID: String): Boolean = optionGroups(categoryID).isNotEmpty()

    fun allLeafOptions(categoryID: String): List<ServiceSubOption> =
        if (usesNestedOptions(categoryID)) {
            optionGroups(categoryID).flatMap { it.children }
        } else {
            subOptions(categoryID)
        }

    fun option(id: String, categoryID: String): ServiceSubOption? =
        allLeafOptions(categoryID).firstOrNull { it.id == id }

    private fun notesChildren(prefix: String, titles: List<String>): List<ServiceSubOption> =
        titles.mapIndexed { index, title ->
            val slug = title.lowercase()
                .replace(Regex("[^a-z0-9]+"), "-")
                .trim('-')
            ServiceSubOption(
                id = "$prefix-${slug.ifEmpty { index.toString() }}",
                title = title,
                allowsNotes = true,
            )
        }
}
