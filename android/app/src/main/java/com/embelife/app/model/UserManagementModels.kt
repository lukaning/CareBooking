package com.embelife.app.model

enum class TeamAccessRole(val title: String, val displayTitle: String) {
    Admin("Admin", "Admin with Full access"),
    Collaborator("Collaborator", "Collaborator"),
    Viewer("Viewer", "Viewer");

    val canEditRole: Boolean get() = this != Admin
    val canExpandPermissions: Boolean get() = this != Admin

    val summaryBullets: List<String>
        get() = when (this) {
            Admin -> listOf(
                "Admin can manage users, roles, and full workspace access.",
                "Admin can NOT be demoted by collaborators or viewers.",
            )
            Collaborator -> listOf(
                "Collaborator can do what what what.",
                "Collaborator can NOT do what what what.",
            )
            Viewer -> listOf(
                "Viewer can do what what what.",
                "Viewer can NOT do what what what.",
            )
        }

    companion object {
        val inviteChoices = listOf(Collaborator, Viewer)
    }
}

enum class FeatureAccessKey(val title: String, val hasNestedItems: Boolean = false) {
    Profile("Profile feature access"),
    Preference("Preference feature access", hasNestedItems = true),
    Booking("Booking/Reschedule feature access"),
    Messaging("Messaging feature access"),
    Payment("Payment feature access", hasNestedItems = true),
    Notes("Notes"),
    Review("Review");

    companion object {
        val nestedLabels = listOf(
            "Address (create/ edit) - care recipient(s)",
            "Phone # (create/ edit) - care recipient(s)",
            "Email (create/ edit) - care recipient(s)",
        )

        fun defaults(forRole: TeamAccessRole): Map<FeatureAccessKey, Boolean> = when (forRole) {
            TeamAccessRole.Admin -> entries.associateWith { true }
            TeamAccessRole.Collaborator, TeamAccessRole.Viewer -> mapOf(
                Profile to true,
                Preference to false,
                Booking to false,
                Messaging to false,
                Payment to true,
                Notes to true,
                Review to true,
            )
        }
    }
}

data class NestedFeatureAccess(
    val id: String,
    val title: String,
    var isEnabled: Boolean,
)

data class ManagedTeamUser(
    val id: String,
    var firstName: String,
    var lastName: String,
    var email: String,
    var role: TeamAccessRole,
    var invitePending: Boolean,
    var permissions: Map<FeatureAccessKey, Boolean>,
    var nestedPermissions: Map<FeatureAccessKey, List<NestedFeatureAccess>>,
) {
    val displayName: String
        get() = firstName.ifEmpty { "$firstName $lastName".trim() }

    val initials: String
        get() {
            val first = firstName.firstOrNull()?.toString().orEmpty()
            val last = lastName.firstOrNull()?.toString().orEmpty()
            return (first + last).uppercase().ifEmpty { "?" }
        }

    companion object {
        fun nestedDefaults(enabled: Boolean = true): Map<FeatureAccessKey, List<NestedFeatureAccess>> =
            FeatureAccessKey.entries.filter { it.hasNestedItems }.associateWith { key ->
                FeatureAccessKey.nestedLabels.mapIndexed { index, title ->
                    NestedFeatureAccess(
                        id = "${key.name.lowercase()}-$index",
                        title = title,
                        isEnabled = enabled,
                    )
                }
            }

        val samples: List<ManagedTeamUser> = listOf(
            ManagedTeamUser("chi", "Chi", "Roger", "chi@embelife.app", TeamAccessRole.Admin, false, FeatureAccessKey.defaults(TeamAccessRole.Admin), nestedDefaults()),
            ManagedTeamUser("john", "John", "Smith", "john@embelife.app", TeamAccessRole.Collaborator, false, FeatureAccessKey.defaults(TeamAccessRole.Collaborator), nestedDefaults()),
            ManagedTeamUser("sharee", "Sharee", "Lee", "sharee@embelife.app", TeamAccessRole.Collaborator, false, FeatureAccessKey.defaults(TeamAccessRole.Collaborator), nestedDefaults()),
            ManagedTeamUser("matt", "Matt", "Nguyen", "matt@embelife.app", TeamAccessRole.Collaborator, false, FeatureAccessKey.defaults(TeamAccessRole.Collaborator), nestedDefaults()),
            ManagedTeamUser("toby", "Toby", "Chen", "toby@embelife.app", TeamAccessRole.Viewer, false, FeatureAccessKey.defaults(TeamAccessRole.Viewer), nestedDefaults()),
        )
    }
}
