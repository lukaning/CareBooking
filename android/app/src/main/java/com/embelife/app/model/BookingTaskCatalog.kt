package com.embelife.app.model

/** Port of `BookingTaskOption`. */
data class BookingTaskOption(
    val categoryID: String,
    val categoryTitle: String,
    val title: String,
) {
    val id: String get() = "$categoryID|$title"
}

/** Port of `BookingTaskCategoryGroup`. */
data class BookingTaskCategoryGroup(
    val id: String,
    val title: String,
    val tasks: List<String>,
) {
    val options: List<BookingTaskOption>
        get() = tasks.map { BookingTaskOption(categoryID = id, categoryTitle = title, title = it) }
}

/** Care task catalog for the booking “Select category” step. */
object BookingTaskCatalog {
    val groups: List<BookingTaskCategoryGroup> = listOf(
        BookingTaskCategoryGroup(
            id = "companionship",
            title = "Companionship/ emotional support",
            tasks = listOf("Companionship/ emotional support"),
        ),
        BookingTaskCategoryGroup(
            id = "meals",
            title = "Meals",
            tasks = listOf(
                "Meal prep/ planning",
                "Grocery shopping/ assistance",
                "Clean/ tidy after meals",
            ),
        ),
        BookingTaskCategoryGroup(
            id = "housekeeping",
            title = "Light housekeeping",
            tasks = listOf(
                "Wash/ put away dishes",
                "Laundry",
                "Linen changes",
                "Tidy areas",
                "Light vacuuming",
                "Dusting",
            ),
        ),
        BookingTaskCategoryGroup(
            id = "medications",
            title = "Medications",
            tasks = listOf(
                "Organize",
                "Reminders",
                "Monitor",
                "Pick up medications from pharmacy",
            ),
        ),
        BookingTaskCategoryGroup(
            id = "mobility",
            title = "Mobility assistance",
            tasks = listOf(
                "Light exercise",
                "Walking",
                "Exercise/ therapy programs assistance",
                "Position changes",
                "Using assistive devices - e.g. crutches, walkers, wheelchairs",
            ),
        ),
        BookingTaskCategoryGroup(
            id = "personal",
            title = "Personal care",
            tasks = listOf(
                "Bathing",
                "Dressing",
                "Grooming",
                "Personal hygiene/ Toileting",
            ),
        ),
        BookingTaskCategoryGroup(
            id = "transport",
            title = "Transportation/ errand assistance",
            tasks = listOf(
                "Drive to/ from appointments",
                "Run errands",
            ),
        ),
    )

    val allOptions: List<BookingTaskOption>
        get() = groups.flatMap { it.options }

    /** Suggested checklist rows derived from selected category chips. */
    fun suggestedChecklist(selected: List<BookingTaskOption>): List<BookingChecklistTask> =
        selected.map { option ->
            BookingChecklistTask(
                title = option.title,
                category = option.categoryTitle,
                subcategory = option.title,
                priority = BookingTaskPriority.Medium,
            )
        }
}
