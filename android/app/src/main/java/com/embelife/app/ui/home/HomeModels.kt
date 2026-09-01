package com.embelife.app.ui.home

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Handshake
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Sell
import androidx.compose.material.icons.filled.Work
import androidx.compose.ui.graphics.vector.ImageVector
import kotlin.math.roundToInt

/** Port of `HomeProviderListMode`. */
enum class HomeProviderListMode(val title: String) {
    YourMatches("Your Matches"),
    SavedProviders("Saved Providers"),
    PreviousProviders("Previous Providers"),
}

/** Port of `HomeFilterCriterion`; SF Symbols map onto the closest Material glyphs. */
enum class HomeFilterCriterion(val label: String, val icon: ImageVector) {
    Location("Location", Icons.Filled.Explore),
    TypeOfHelp("Type of Help", Icons.Filled.Handshake),
    ForWho("For Who", Icons.Filled.Eco),
    AgeRange("Age Range", Icons.Filled.Campaign),
    GenderIdentity("Gender Identity", Icons.Filled.People),
    Language("Language", Icons.Filled.Language),
    PriceRange("Price Range", Icons.Filled.Sell),
    SpecialNeed("Special need", Icons.Filled.Work),
}

/** Port of `HomeFilterState`. */
data class HomeFilterState(
    val location: String = "California; Bay Area",
    val typeOfHelp: String = "Child Care",
    val forWho: String = "Child",
    val careRecipientAgeGroup: String = "3-5",
    val ageRanges: List<String> = listOf("25-30", "30-35"),
    val genderIdentity: String = "Female",
    val languages: List<String> = listOf("English"),
    val minPrice: Float = 15f,
    val maxPrice: Float = 30f,
    val specialNeed: String = "AD&D",
) {
    fun chipSummary(criterion: HomeFilterCriterion): String = when (criterion) {
        HomeFilterCriterion.Location -> "in $location"
        HomeFilterCriterion.TypeOfHelp -> typeOfHelp
        HomeFilterCriterion.ForWho -> "$forWho; Age Group: $careRecipientAgeGroup"
        HomeFilterCriterion.AgeRange -> ageRanges.joinToString("; ")
        HomeFilterCriterion.GenderIdentity -> genderIdentity
        HomeFilterCriterion.Language -> languages.ifEmpty { listOf("Any") }.joinToString("; ")
        HomeFilterCriterion.PriceRange -> "$${minPrice.roundToInt()} - $${maxPrice.roundToInt()}"
        HomeFilterCriterion.SpecialNeed -> specialNeed
    }
}

/** Port of `BookingAppointmentType`. */
enum class BookingAppointmentType(val title: String) {
    InPerson("In-person Appointment"),
    Video("Video Appointment"),
}

/** Option lists backing `FilterSheet`. */
object FilterOptions {
    val location = listOf(
        "California; Bay Area",
        "California; Los Angeles",
        "New York; NYC",
        "Texas; Austin",
        "Remote only",
    )
    val typeOfHelp = listOf(
        "Child Care",
        "Personal Care",
        "Postpartum",
        "Companionship",
        "Special Needs",
        "Respite Care",
    )
    val forWho = listOf("Child", "Parent", "Spouse", "Self", "Other Family")
    val careAgeGroup = listOf("0-2", "3-5", "6-12", "13-17", "18+", "Senior")
    val ageRange = listOf("18-25", "25-30", "30-35", "35-45", "45-55", "55+")
    val gender = listOf("Any", "Female", "Male", "Non-binary", "Prefer not to say")
    val language = listOf("English", "Spanish", "Mandarin", "Cantonese", "French", "ASL")
    val specialNeed = listOf(
        "None",
        "AD&D",
        "Mobility support",
        "Cognitive support",
        "Sensory support",
        "Medical monitoring",
    )

    val priceBounds = 15f..150f
}
