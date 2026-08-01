import Foundation
import SwiftUI

enum NotificationSection: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"

    var id: String { rawValue }
}

struct AppNotificationItem: Identifiable, Hashable {
    var id: String
    var section: NotificationSection
    var senderName: String
    var title: String
    var metaLine: String?
    var taskDetail: String?
    var timeLabel: String
    var isUnread: Bool
    var messageBubble: String?
    var attachmentCount: Int
    var showsActions: Bool
    var avatarColor: Color

    var initials: String {
        String(senderName.prefix(1)).uppercased()
    }

    static let samples: [AppNotificationItem] = [
        AppNotificationItem(
            id: "notif-1",
            section: .today,
            senderName: "Marina",
            title: "Marina have accepted your booking request",
            metaLine: "• What time • Which day",
            taskDetail: "Task Checklist Details here....",
            timeLabel: "19m ago",
            isUnread: true,
            attachmentCount: 0,
            showsActions: false,
            avatarColor: Color(red: 0.55, green: 0.72, blue: 0.88)
        ),
        AppNotificationItem(
            id: "notif-2",
            section: .today,
            senderName: "Hariz",
            title: "Hariz has completed the task and updated on comments",
            metaLine: nil,
            taskDetail: nil,
            timeLabel: "9h ago",
            isUnread: true,
            messageBubble: "Some cleaning product has finished, can you get a new one?",
            attachmentCount: 0,
            showsActions: false,
            avatarColor: Color(red: 0.68, green: 0.58, blue: 0.88)
        ),
        AppNotificationItem(
            id: "notif-3",
            section: .yesterday,
            senderName: "Iqbal",
            title: "Iqbal attached photos on the task at 299 spear street",
            metaLine: nil,
            taskDetail: nil,
            timeLabel: "1d ago",
            isUnread: false,
            attachmentCount: 3,
            showsActions: false,
            avatarColor: Color(red: 0.45, green: 0.68, blue: 0.55)
        ),
        AppNotificationItem(
            id: "notif-4",
            section: .yesterday,
            senderName: "Lela",
            title: "Lela message you directly",
            metaLine: nil,
            taskDetail: nil,
            timeLabel: "1d ago",
            isUnread: false,
            messageBubble: "What about Thursday afternoon?",
            attachmentCount: 0,
            showsActions: true,
            avatarColor: Color(red: 0.92, green: 0.55, blue: 0.62)
        )
    ]
}
