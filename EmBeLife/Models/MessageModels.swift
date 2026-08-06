import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Hashable {
    enum Sender: Hashable {
        case me
        case them
    }

    var id: String
    var text: String
    var sender: Sender
    var sentAt: Date
}

struct MessageThread: Identifiable, Hashable {
    var id: String
    var name: String
    var preview: String
    var timeLabel: String
    var isOnline: Bool
    var isUnread: Bool
    var isTyping: Bool
    var avatarColor: Color
    var messages: [ChatMessage]

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    var lastMessageText: String {
        messages.last?.text ?? preview
    }

    static let samples: [MessageThread] = {
        let calendar = Calendar.current
        func today(hour: Int, minute: Int) -> Date {
            calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: Date()
            ) ?? Date()
        }

        return [
            MessageThread(
                id: "msg-1",
                name: "Bogdan Krivenchenko",
                preview: "Hi! How are things with the ill...",
                timeLabel: "08:30",
                isOnline: true,
                isUnread: false,
                isTyping: true,
                avatarColor: Color(red: 0.55, green: 0.72, blue: 0.88),
                messages: [
                    ChatMessage(
                        id: "b1",
                        text: "Hi Luka, I accept your lesson request. (I offer my 1st lesson for free so that we can get to know each other.) To organize the first lesson, let me know your availabilities. Thanks, BK",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 25)
                    ),
                    ChatMessage(
                        id: "b2",
                        text: "Here are some recommended books for the kids age around 5-6",
                        sender: .me,
                        sentAt: today(hour: 8, minute: 28)
                    ),
                    ChatMessage(
                        id: "b3",
                        text: "Perfect, thank you! I’ll review those books tonight and propose a few time slots.",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 30)
                    )
                ]
            ),
            MessageThread(
                id: "msg-2",
                name: "Lesya Borodina",
                preview: "Are you still interested?",
                timeLabel: "08:15",
                isOnline: false,
                isUnread: true,
                isTyping: false,
                avatarColor: Color(red: 0.92, green: 0.55, blue: 0.62),
                messages: [
                    ChatMessage(
                        id: "l1",
                        text: "Hi! Just checking in about the care plan we discussed last week.",
                        sender: .them,
                        sentAt: today(hour: 7, minute: 50)
                    ),
                    ChatMessage(
                        id: "l2",
                        text: "Yes, still interested. Can we talk tomorrow afternoon?",
                        sender: .me,
                        sentAt: today(hour: 8, minute: 5)
                    ),
                    ChatMessage(
                        id: "l3",
                        text: "Are you still interested?",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 15)
                    )
                ]
            ),
            MessageThread(
                id: "msg-3",
                name: "Sergey Filatov",
                preview: "I would think about the proposal...",
                timeLabel: "08:13",
                isOnline: false,
                isUnread: true,
                isTyping: false,
                avatarColor: Color(red: 0.68, green: 0.58, blue: 0.88),
                messages: [
                    ChatMessage(
                        id: "s1",
                        text: "Thanks for sending the proposal over.",
                        sender: .them,
                        sentAt: today(hour: 7, minute: 40)
                    ),
                    ChatMessage(
                        id: "s2",
                        text: "Happy to adjust hours if weekends work better for you.",
                        sender: .me,
                        sentAt: today(hour: 7, minute: 55)
                    ),
                    ChatMessage(
                        id: "s3",
                        text: "I would think about the proposal. Can we revisit tomorrow?",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 13)
                    )
                ]
            ),
            MessageThread(
                id: "msg-4",
                name: "Alpamys Moldashev",
                preview: "Have you seen this...",
                timeLabel: "08:09",
                isOnline: true,
                isUnread: false,
                isTyping: false,
                avatarColor: Color(red: 0.45, green: 0.68, blue: 0.55),
                messages: [
                    ChatMessage(
                        id: "a1",
                        text: "Have you seen this schedule update for next week?",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 9)
                    ),
                    ChatMessage(
                        id: "a2",
                        text: "Not yet — opening it now.",
                        sender: .me,
                        sentAt: today(hour: 8, minute: 10)
                    )
                ]
            ),
            MessageThread(
                id: "msg-5",
                name: "Julia Rokina",
                preview: "I think we need to think about it in mor...",
                timeLabel: "08:04",
                isOnline: false,
                isUnread: false,
                isTyping: false,
                avatarColor: Color(red: 0.88, green: 0.62, blue: 0.45),
                messages: [
                    ChatMessage(
                        id: "j1",
                        text: "I think we need to think about it in more detail before next Monday.",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 4)
                    )
                ]
            ),
            MessageThread(
                id: "msg-6",
                name: "Maxim Kamolin",
                preview: "here is my timeslots",
                timeLabel: "08:02",
                isOnline: false,
                isUnread: false,
                isTyping: false,
                avatarColor: Color(red: 0.42, green: 0.55, blue: 0.78),
                messages: [
                    ChatMessage(
                        id: "m1",
                        text: "here is my timeslots",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 2)
                    ),
                    ChatMessage(
                        id: "m2",
                        text: "Got it, Thursday morning works for us.",
                        sender: .me,
                        sentAt: today(hour: 8, minute: 3)
                    )
                ]
            ),
            MessageThread(
                id: "msg-7",
                name: "Daniel Falka",
                preview: "here is my timeslots",
                timeLabel: "08:02",
                isOnline: false,
                isUnread: false,
                isTyping: false,
                avatarColor: Color(red: 0.78, green: 0.48, blue: 0.52),
                messages: [
                    ChatMessage(
                        id: "d1",
                        text: "here is my timeslots",
                        sender: .them,
                        sentAt: today(hour: 8, minute: 2)
                    )
                ]
            )
        ]
    }()
}
