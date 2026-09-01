package com.embelife.app.model

import androidx.compose.ui.graphics.Color
import java.util.UUID

enum class MemberAvatarStyle(val color: Color) {
    Pink(Color(0xFFFAB3C7)),
    Orange(Color(0xFFFFB873)),
    Purple(Color(0xFFB89EF2)),
    Green(Color(0xFF8CD1A6)),
    Blue(Color(0xFF8CB8F2));

    companion object {
        fun next(after: Int): MemberAvatarStyle = entries[after % entries.size]
    }
}

data class FamilyMember(
    val id: UUID = UUID.randomUUID(),
    var firstName: String,
    var lastName: String,
    var preferredServices: List<String> = emptyList(),
    var preferredTimes: List<String> = emptyList(),
    var avatarStyle: MemberAvatarStyle = MemberAvatarStyle.Pink,
) {
    val displayName: String
        get() {
            if (lastName.isEmpty()) return firstName
            if (firstName.contains(".")) {
                return "$firstName. $lastName".replace("..", ".")
            }
            val letter = firstName.firstOrNull()?.toString() ?: "?"
            return "$letter. $lastName"
        }

    val monogram: String
        get() = firstName.firstOrNull()?.toString() ?: "?"

    companion object {
        val preferredServiceOptions = listOf(
            "Personal care/ hygiene",
            "Mobility assistance",
            "House keeping",
            "Companionship",
            "Meal prep",
            "Transportation",
            "Light housekeeping",
        )

        val preferredTimeOptions = listOf(
            "8am – 10am",
            "10am – 1pm",
            "1pm – 3pm",
            "3pm – 6pm",
            "6pm – 8pm",
        )

        val samples: List<FamilyMember> = listOf(
            FamilyMember(
                firstName = "S",
                lastName = "Roger",
                preferredServices = listOf("Personal care/ hygiene", "Mobility assistance", "House keeping"),
                preferredTimes = listOf("8am – 10am", "3pm – 6pm"),
                avatarStyle = MemberAvatarStyle.Pink,
            ),
            FamilyMember(
                firstName = "J.M.S",
                lastName = "Roger",
                preferredServices = listOf("Companionship", "Meal prep"),
                preferredTimes = listOf("9am – 12pm"),
                avatarStyle = MemberAvatarStyle.Orange,
            ),
            FamilyMember(
                firstName = "J",
                lastName = "Roger",
                preferredServices = listOf("Transportation"),
                preferredTimes = listOf("1pm – 3pm"),
                avatarStyle = MemberAvatarStyle.Purple,
            ),
            FamilyMember(
                firstName = "M",
                lastName = "Roger",
                preferredServices = listOf("Light housekeeping"),
                preferredTimes = listOf("10am – 1pm"),
                avatarStyle = MemberAvatarStyle.Green,
            ),
        )
    }
}

data class UserProfile(
    var firstName: String = "",
    var middleName: String = "",
    var lastName: String = "",
    var address: String = "",
    var email: String = "",
    var mobile: String = "",
    var languages: List<String> = emptyList(),
    var familyMembers: List<FamilyMember> = emptyList(),
    var hasUploadedPhoto: Boolean = false,
    var rating: Double = 4.8,
    var reviewCount: Int = 5,
    var roleLabel: String = "Customer",
    var accountType: String = "Owner Account",
    var servicesRequestedFor: String = "",
    var isPublished: Boolean = false,
) {
    val fullName: String
        get() = listOf(firstName, middleName, lastName)
            .filter { it.isNotBlank() }
            .joinToString(" ")

    val displayFirstLast: String
        get() = listOf(firstName, lastName)
            .filter { it.isNotEmpty() }
            .joinToString(" ")

    val hasMinimumContact: Boolean
        get() = firstName.isNotEmpty() && lastName.isNotEmpty() && address.isNotEmpty()

    val isFilled: Boolean
        get() = isPublished && hasMinimumContact
}
