import SwiftUI

struct MessagesView: View {
    @State private var threads = MessageThread.samples
    @State private var selectedThreadID: String?

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
                        Button {
                            openThread(thread.id)
                        } label: {
                            messageRow(thread)
                        }
                        .buttonStyle(.plain)
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
            .navigationDestination(item: $selectedThreadID) { id in
                if let index = threads.firstIndex(where: { $0.id == id }) {
                    ConversationView(thread: $threads[index])
                } else {
                    ContentUnavailableView("Conversation", systemImage: "bubble.left.and.bubble.right")
                }
            }
            .task {
                await runLivePresenceLoop()
            }
        }
    }

    private func openThread(_ id: String) {
        if let index = threads.firstIndex(where: { $0.id == id }) {
            threads[index].isUnread = false
            threads[index].isTyping = false
        }
        selectedThreadID = id
    }

    @MainActor
    private func runLivePresenceLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(3.2))
            guard let index = threads.firstIndex(where: { $0.id == "msg-1" }) else { return }
            if selectedThreadID != "msg-1" {
                threads[index].isOnline = true
                threads[index].isTyping.toggle()
                if threads[index].isTyping {
                    threads[index].preview = "Typing..."
                } else {
                    threads[index].preview = threads[index].lastMessageText
                }
            }
        }
    }

    private func messageRow(_ thread: MessageThread) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MessageAvatarView(
                initials: thread.initials,
                color: thread.avatarColor,
                isOnline: thread.isOnline,
                size: 48
            )

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
                    Text(thread.isTyping ? "Typing..." : thread.preview)
                        .font(.subheadline)
                        .foregroundStyle(thread.isTyping ? Theme.brandOrange : previewColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if thread.isUnread {
                        Circle()
                            .fill(unreadDot)
                            .frame(width: 9, height: 9)
                            .accessibilityLabel("Unread")
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
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }
}

// MARK: - Conversation

struct ConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var thread: MessageThread

    @State private var draft = ""
    @State private var scrollToID: String?
    @FocusState private var isComposerFocused: Bool

    private let nameColor = Color(red: 0.18, green: 0.24, blue: 0.36)
    private let secondaryColor = Color(red: 0.65, green: 0.68, blue: 0.75)
    private let outgoingBubble = Color(red: 0.30, green: 0.36, blue: 0.45)
    private let incomingText = Color(red: 0.22, green: 0.20, blue: 0.35)
    private let onlineDot = Color(red: 0.30, green: 0.78, blue: 0.45)
    private let meOrange = Theme.brandOrange

    var body: some View {
        VStack(spacing: 0) {
            conversationHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(thread.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if thread.isTyping {
                            typingBubble
                                .id("typing-indicator")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
                .background(Color(.systemBackground))
                .onChange(of: thread.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: thread.isTyping) { _, typing in
                    if typing { scrollToBottom(proxy) }
                }
                .onAppear {
                    scrollToBottom(proxy)
                    startLiveTypingCycle()
                }
            }

            composerBar
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            thread.isUnread = false
        }
        .onDisappear {
            if let last = thread.messages.last {
                thread.preview = last.text
                thread.timeLabel = Self.timeLabel(for: last.sentAt)
            }
        }
    }

    private var conversationHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            MessageAvatarView(
                initials: thread.initials,
                color: thread.avatarColor,
                isOnline: thread.isOnline,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(thread.name)
                    .font(.body.weight(.bold))
                    .foregroundStyle(nameColor)
                    .lineLimit(1)

                Text(thread.isTyping ? "Typing..." : (thread.isOnline ? "Active now" : "Offline"))
                    .font(.caption)
                    .foregroundStyle(secondaryColor)
            }

            Spacer(minLength: 8)

            Text(thread.isOnline ? "Online" : "Offline")
                .font(.subheadline)
                .foregroundStyle(secondaryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.sender == .them {
                MessageAvatarView(
                    initials: thread.initials,
                    color: thread.avatarColor,
                    isOnline: false,
                    size: 36
                )
                bubbleText(message.text, outgoing: false)
                Spacer(minLength: 36)
            } else {
                Spacer(minLength: 36)
                bubbleText(message.text, outgoing: true)
                meAvatar
            }
        }
    }

    private var typingBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            MessageAvatarView(
                initials: thread.initials,
                color: thread.avatarColor,
                isOnline: false,
                size: 36
            )
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(secondaryColor.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .offset(y: bounceOffset(for: index))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            Spacer(minLength: 36)
        }
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: thread.isTyping)
    }

    private func bounceOffset(for index: Int) -> CGFloat {
        thread.isTyping ? CGFloat((index % 2 == 0) ? -2 : 2) : 0
    }

    private func bubbleText(_ text: String, outgoing: Bool) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(outgoing ? Color.white : incomingText)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(outgoing ? outgoingBubble : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(outgoing ? 0.04 : 0.06), radius: 6, y: 2)
    }

    private var meAvatar: some View {
        Image(systemName: "person.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(meOrange)
            .clipShape(Circle())
    }

    private var composerBar: some View {
        HStack(spacing: 12) {
            meAvatar

            HStack(spacing: 10) {
                TextField("Write your message...", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.body)
                    .focused($isComposerFocused)
                    .onSubmit(sendDraft)

                Button {
                    // Emoji placeholder
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundStyle(secondaryColor)
                }
                .buttonStyle(.plain)

                Button {
                    // Attachment placeholder
                } label: {
                    Image(systemName: "paperclip")
                        .font(.title3)
                        .foregroundStyle(secondaryColor)
                }
                .buttonStyle(.plain)

                if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: sendDraft) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.brandOrange)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 8, y: -2)
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let message = ChatMessage(
            id: UUID().uuidString,
            text: text,
            sender: .me,
            sentAt: Date()
        )
        thread.messages.append(message)
        thread.preview = text
        thread.timeLabel = Self.timeLabel(for: message.sentAt)
        thread.isTyping = false
        draft = ""
        isComposerFocused = false

        // Live reply simulation
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            thread.isTyping = true
            try? await Task.sleep(for: .seconds(1.6))
            thread.isTyping = false
            let reply = ChatMessage(
                id: UUID().uuidString,
                text: "Thanks for the update — I'll get back to you shortly.",
                sender: .them,
                sentAt: Date()
            )
            thread.messages.append(reply)
            thread.preview = reply.text
            thread.timeLabel = Self.timeLabel(for: reply.sentAt)
        }
    }

    private func startLiveTypingCycle() {
        guard thread.isOnline else { return }
        Task { @MainActor in
            // Brief typing pulse when opening an online conversation.
            try? await Task.sleep(for: .seconds(0.8))
            if thread.messages.last?.sender == .me || thread.id == "msg-1" {
                thread.isTyping = true
                try? await Task.sleep(for: .seconds(2.0))
                thread.isTyping = false
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        let anchor = thread.isTyping ? "typing-indicator" : thread.messages.last?.id
        guard let anchor else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(anchor, anchor: .bottom)
        }
    }

    private static func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Shared avatar

private struct MessageAvatarView: View {
    let initials: String
    let color: Color
    let isOnline: Bool
    var size: CGFloat = 48

    private let onlineDot = Color(red: 0.30, green: 0.78, blue: 0.45)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(initials)
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())

            if isOnline {
                Circle()
                    .fill(onlineDot)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 1, y: 1)
            }
        }
    }
}

#Preview("List") {
    MessagesView()
}

#Preview("Conversation") {
    @Previewable @State var thread = MessageThread.samples[0]
    NavigationStack {
        ConversationView(thread: $thread)
    }
}
