import SwiftUI

struct MessagesView: View {
    private let threads = MessageThread.samples

    private let nameColor = Color(red: 0.18, green: 0.24, blue: 0.36)
    private let previewColor = Color(red: 0.55, green: 0.58, blue: 0.68)
    private let timeColor = Color(red: 0.65, green: 0.68, blue: 0.75)
    private let unreadDot = Color(red: 0.20, green: 0.55, blue: 0.95)
    private let onlineDot = Color(red: 0.30, green: 0.78, blue: 0.45)
    private let cardBorder = Color(red: 0.92, green: 0.93, blue: 0.95)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(threads) { thread in
                        messageRow(thread)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Messages")
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

    private func messageRow(_ thread: MessageThread) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Text(thread.initials)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(thread.avatarColor)
                    .clipShape(Circle())

                if thread.isOnline {
                    Circle()
                        .fill(onlineDot)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(thread.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(nameColor)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(thread.timeLabel)
                        .font(.caption)
                        .foregroundStyle(timeColor)
                }

                HStack(alignment: .center) {
                    Text(thread.preview)
                        .font(.subheadline)
                        .foregroundStyle(previewColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if thread.isUnread {
                        Circle()
                            .fill(unreadDot)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    MessagesView()
}
