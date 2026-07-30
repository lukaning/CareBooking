import SwiftUI

struct NotificationView: View {
    private let items = AppNotificationItem.samples

    private let titleColor = Color(red: 0.12, green: 0.14, blue: 0.18)
    private let metaColor = Color(red: 0.55, green: 0.58, blue: 0.68)
    private let timeColor = Color(red: 0.65, green: 0.68, blue: 0.75)
    private let unreadDot = Color(red: 0.20, green: 0.55, blue: 0.95)
    private let readDot = Color(red: 0.88, green: 0.89, blue: 0.91)
    private let bubbleBlue = Color(red: 0.20, green: 0.55, blue: 0.95)
    private let acceptGreen = Color(red: 0.18, green: 0.72, blue: 0.45)
    private let declineRed = Color(red: 0.92, green: 0.35, blue: 0.35)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(NotificationSection.allCases) { section in
                        let sectionItems = items.filter { $0.section == section }
                        if !sectionItems.isEmpty {
                            sectionHeader(section.rawValue)
                            ForEach(sectionItems) { item in
                                notificationRow(item)
                                if item.id != sectionItems.last?.id {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Menu placeholder
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                    }
                    .accessibilityLabel("More options")
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(titleColor)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private func notificationRow(_ item: AppNotificationItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(item.initials)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(item.avatarColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 6) {
                        Circle()
                            .fill(item.isUnread ? unreadDot : readDot)
                            .frame(width: 10, height: 10)
                        Text(item.timeLabel)
                            .font(.caption2)
                            .foregroundStyle(timeColor)
                    }
                }

                if let metaLine = item.metaLine {
                    Text(metaLine)
                        .font(.caption)
                        .foregroundStyle(metaColor)
                }

                if let taskDetail = item.taskDetail {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                            .foregroundStyle(metaColor)
                        Text(taskDetail)
                            .font(.caption)
                            .foregroundStyle(metaColor)
                    }
                }

                if let bubble = item.messageBubble {
                    Text(bubble)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if item.attachmentCount > 0 {
                    HStack(spacing: 8) {
                        ForEach(0..<item.attachmentCount, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.90 + Double(index) * 0.02, green: 0.91, blue: 0.93))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.caption)
                                        .foregroundStyle(metaColor)
                                }
                        }
                    }
                }

                if item.showsActions {
                    HStack(spacing: 12) {
                        actionButton(
                            title: "Accept",
                            icon: "checkmark",
                            color: acceptGreen
                        )
                        actionButton(
                            title: "Decline",
                            icon: "xmark",
                            color: declineRed
                        )
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func actionButton(title: String, icon: String, color: Color) -> some View {
        Button {
            // Action placeholder
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotificationView()
}
