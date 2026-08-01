import Foundation
import SwiftUI

struct MessageThread: Identifiable, Hashable {
    var id: String
    var name: String
    var preview: String
    var timeLabel: String
    var isOnline: Bool
    var isUnread: Bool
    var avatarColor: Color

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    static let samples: [MessageThread] = [
        MessageThread(
            id: "msg-1",
            name: "Bogdan Krivenchenko",
            preview: "Hi! How are things with the ill...",
            timeLabel: "08:30",
            isOnline: true,
            isUnread: false,
            avatarColor: Color(red: 0.55, green: 0.72, blue: 0.88)
        ),
        MessageThread(
            id: "msg-2",
            name: "Lesya Borodina",
            preview: "Are you still interested?",
            timeLabel: "08:15",
            isOnline: false,
            isUnread: true,
            avatarColor: Color(red: 0.92, green: 0.55, blue: 0.62)
        ),
        MessageThread(
            id: "msg-3",
            name: "Sergey Filatov",
            preview: "I would think about the proposal...",
            timeLabel: "08:13",
            isOnline: false,
            isUnread: true,
            avatarColor: Color(red: 0.68, green: 0.58, blue: 0.88)
        ),
        MessageThread(
            id: "msg-4",
            name: "Alpamys Moldashev",
            preview: "Have you seen this...",
            timeLabel: "08:09",
            isOnline: false,
            isUnread: false,
            avatarColor: Color(red: 0.45, green: 0.68, blue: 0.55)
        ),
        MessageThread(
            id: "msg-5",
            name: "Julia Rokina",
            preview: "I think we need to think about it in mor...",
            timeLabel: "08:04",
            isOnline: false,
            isUnread: false,
            avatarColor: Color(red: 0.88, green: 0.62, blue: 0.45)
        ),
        MessageThread(
            id: "msg-6",
            name: "Maxim Kamolin",
            preview: "here is my timeslots",
            timeLabel: "08:02",
            isOnline: false,
            isUnread: false,
            avatarColor: Color(red: 0.42, green: 0.55, blue: 0.78)
        ),
        MessageThread(
            id: "msg-7",
            name: "Daniel Falka",
            preview: "here is my timeslots",
            timeLabel: "08:02",
            isOnline: false,
            isUnread: false,
            avatarColor: Color(red: 0.78, green: 0.48, blue: 0.52)
        )
    ]
}
