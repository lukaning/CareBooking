package com.embelife.app.model

import androidx.compose.ui.graphics.Color
import java.time.LocalDateTime

enum class ChatSender { Me, Them }

data class ChatMessage(
    val id: String,
    val text: String,
    val sender: ChatSender,
    val sentAt: LocalDateTime,
)

data class MessageThread(
    val id: String,
    var name: String,
    var preview: String,
    var timeLabel: String,
    var isOnline: Boolean,
    var isUnread: Boolean,
    var isTyping: Boolean,
    val avatarColor: Color,
    var messages: List<ChatMessage>,
) {
    val initials: String
        get() {
            val parts = name.split(" ").filter { it.isNotEmpty() }
            val first = parts.firstOrNull()?.firstOrNull()?.toString().orEmpty()
            val last = parts.getOrNull(1)?.firstOrNull()?.toString().orEmpty()
            return (first + last).uppercase().ifEmpty { "?" }
        }

    val lastMessageText: String
        get() = messages.lastOrNull()?.text ?: preview

    companion object {
        private fun today(hour: Int, minute: Int): LocalDateTime =
            LocalDateTime.now().withHour(hour).withMinute(minute).withSecond(0).withNano(0)

        val samples: List<MessageThread> = listOf(
            MessageThread(
                id = "msg-1",
                name = "Bogdan Krivenchenko",
                preview = "Hi! How are things with the ill...",
                timeLabel = "08:30",
                isOnline = true,
                isUnread = false,
                isTyping = true,
                avatarColor = Color(0xFF8CB8E0),
                messages = listOf(
                    ChatMessage("b1", "Hi Luka, I accept your lesson request. (I offer my 1st lesson for free so that we can get to know each other.) To organize the first lesson, let me know your availabilities. Thanks, BK", ChatSender.Them, today(8, 25)),
                    ChatMessage("b2", "Here are some recommended books for the kids age around 5-6", ChatSender.Me, today(8, 28)),
                    ChatMessage("b3", "Perfect, thank you! I’ll review those books tonight and propose a few time slots.", ChatSender.Them, today(8, 30)),
                ),
            ),
            MessageThread(
                id = "msg-2",
                name = "Lesya Borodina",
                preview = "Are you still interested?",
                timeLabel = "08:15",
                isOnline = false,
                isUnread = true,
                isTyping = false,
                avatarColor = Color(0xFFEB8C9E),
                messages = listOf(
                    ChatMessage("l1", "Hi! Just checking in about the care plan we discussed last week.", ChatSender.Them, today(7, 50)),
                    ChatMessage("l2", "Yes, still interested. Can we talk tomorrow afternoon?", ChatSender.Me, today(8, 5)),
                    ChatMessage("l3", "Are you still interested?", ChatSender.Them, today(8, 15)),
                ),
            ),
            MessageThread(
                id = "msg-3",
                name = "Sergey Filatov",
                preview = "I would think about the proposal...",
                timeLabel = "08:13",
                isOnline = false,
                isUnread = true,
                isTyping = false,
                avatarColor = Color(0xFFAD94E0),
                messages = listOf(
                    ChatMessage("s1", "Thanks for sending the proposal over.", ChatSender.Them, today(7, 40)),
                    ChatMessage("s2", "Happy to adjust hours if weekends work better for you.", ChatSender.Me, today(7, 55)),
                    ChatMessage("s3", "I would think about the proposal. Can we revisit tomorrow?", ChatSender.Them, today(8, 13)),
                ),
            ),
            MessageThread(
                id = "msg-4",
                name = "Alpamys Moldashev",
                preview = "Have you seen this...",
                timeLabel = "08:09",
                isOnline = true,
                isUnread = false,
                isTyping = false,
                avatarColor = Color(0xFF73AD8C),
                messages = listOf(
                    ChatMessage("a1", "Have you seen this schedule update for next week?", ChatSender.Them, today(8, 9)),
                    ChatMessage("a2", "Not yet — opening it now.", ChatSender.Me, today(8, 10)),
                ),
            ),
            MessageThread(
                id = "msg-5",
                name = "Julia Rokina",
                preview = "I think we need to think about it in mor...",
                timeLabel = "08:04",
                isOnline = false,
                isUnread = false,
                isTyping = false,
                avatarColor = Color(0xFFE09E73),
                messages = listOf(
                    ChatMessage("j1", "I think we need to think about it in more detail before next Monday.", ChatSender.Them, today(8, 4)),
                ),
            ),
            MessageThread(
                id = "msg-6",
                name = "Maxim Kamolin",
                preview = "here is my timeslots",
                timeLabel = "08:02",
                isOnline = false,
                isUnread = false,
                isTyping = false,
                avatarColor = Color(0xFF6B8CC7),
                messages = listOf(
                    ChatMessage("m1", "here is my timeslots", ChatSender.Them, today(8, 2)),
                    ChatMessage("m2", "Got it, Thursday morning works for us.", ChatSender.Me, today(8, 3)),
                ),
            ),
            MessageThread(
                id = "msg-7",
                name = "Daniel Falka",
                preview = "here is my timeslots",
                timeLabel = "08:02",
                isOnline = false,
                isUnread = false,
                isTyping = false,
                avatarColor = Color(0xFFC77A85),
                messages = listOf(
                    ChatMessage("d1", "here is my timeslots", ChatSender.Them, today(8, 2)),
                ),
            ),
        )
    }
}
