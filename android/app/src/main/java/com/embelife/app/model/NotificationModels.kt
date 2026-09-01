package com.embelife.app.model

import androidx.compose.ui.graphics.Color

enum class NotificationSection(val title: String) {
    Today("Today"),
    Yesterday("Yesterday"),
}

data class AppNotificationItem(
    val id: String,
    val section: NotificationSection,
    val senderName: String,
    val title: String,
    val metaLine: String? = null,
    val taskDetail: String? = null,
    val timeLabel: String,
    val isUnread: Boolean,
    val messageBubble: String? = null,
    val attachmentCount: Int = 0,
    val showsActions: Boolean = false,
    val avatarColor: Color,
) {
    val initials: String
        get() = senderName.firstOrNull()?.uppercaseChar()?.toString() ?: "?"

    companion object {
        val samples: List<AppNotificationItem> = listOf(
            AppNotificationItem(
                id = "notif-1",
                section = NotificationSection.Today,
                senderName = "Marina",
                title = "Marina have accepted your booking request",
                metaLine = "• What time • Which day",
                taskDetail = "Task Checklist Details here....",
                timeLabel = "19m ago",
                isUnread = true,
                avatarColor = Color(0xFF8CB8E0),
            ),
            AppNotificationItem(
                id = "notif-2",
                section = NotificationSection.Today,
                senderName = "Hariz",
                title = "Hariz has completed the task and updated on comments",
                timeLabel = "9h ago",
                isUnread = true,
                messageBubble = "Some cleaning product has finished, can you get a new one?",
                avatarColor = Color(0xFFAD94E0),
            ),
            AppNotificationItem(
                id = "notif-3",
                section = NotificationSection.Yesterday,
                senderName = "Iqbal",
                title = "Iqbal attached photos on the task at 299 spear street",
                timeLabel = "1d ago",
                isUnread = false,
                attachmentCount = 3,
                avatarColor = Color(0xFF73AD8C),
            ),
            AppNotificationItem(
                id = "notif-4",
                section = NotificationSection.Yesterday,
                senderName = "Lela",
                title = "Lela message you directly",
                timeLabel = "1d ago",
                isUnread = false,
                messageBubble = "What about Thursday afternoon?",
                showsActions = true,
                avatarColor = Color(0xFFEB8C9E),
            ),
        )
    }
}
