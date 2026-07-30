import SwiftUI

struct NotesView: View {
    @Environment(AppModel.self) private var appModel
    @State private var screenPhase: NotesScreenPhase = .welcome
    @State private var conversationPhase: VoiceConversationPhase = .listening
    @State private var isPlaying = false
    @State private var typedInput = ""
    @State private var showTypeSheet = false

    private let pageBG = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let userBubble = Color(red: 0.90, green: 0.84, blue: 0.94)
    private let aiBubble = Color(red: 0.82, green: 0.90, blue: 0.98)
    private let statusGray = Color(red: 0.55, green: 0.58, blue: 0.65)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBG.ignoresSafeArea()

                switch screenPhase {
                case .welcome:
                    welcomeContent
                case .ready:
                    readyContent
                case .conversation:
                    conversationContent
                }
            }
            .navigationBarHidden(screenPhase == .conversation)
            .toolbar(screenPhase == .conversation ? .hidden : .visible, for: .navigationBar)
            .sheet(isPresented: $showTypeSheet) {
                typeInputSheet
            }
        }
    }

    // MARK: - Welcome

    private var welcomeContent: some View {
        VStack(spacing: 0) {
            HeroHeaderImage()

            VStack(alignment: .leading, spacing: 12) {
                greetingHeader

                Text("Find vetted and trustworthy care…\nFor all of life's stages")
                    .font(.body)
                    .foregroundStyle(Theme.grayscale70)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 24)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        screenPhase = .ready
                    }
                } label: {
                    Text("Get Started")
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Ready (mic)

    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            orangeStatusBar

            VStack(alignment: .leading, spacing: 12) {
                greetingHeader
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            Button {
                startConversation()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Theme.brandOrange)
                    .clipShape(Circle())
                    .shadow(color: Theme.brandOrange.opacity(0.35), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Text("Press to talk to me")
                .font(.title3.weight(.semibold))
                .foregroundStyle(statusGray)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

            Spacer()
        }
    }

    // MARK: - Conversation

    private var conversationContent: some View {
        VStack(spacing: 0) {
            orangeStatusBar
            conversationTopBar

            ScrollView {
                VStack(spacing: 20) {
                    listeningVisualizer
                        .padding(.top, 24)

                    if conversationPhase != .listening {
                        userMessageBubble
                    }

                    if conversationPhase == .playback || conversationPhase == .aiReply {
                        audioPlaybackCard
                        translateButton
                    }

                    if conversationPhase == .aiReply {
                        aiReplySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            conversationBottomBar
        }
    }

    private var conversationTopBar: some View {
        HStack(spacing: 12) {
            Button {
                showTypeSheet = true
            } label: {
                topActionCard(icon: "ellipsis.message", title: "Type", iconColor: Theme.grayscale70)
            }
            .buttonStyle(.plain)

            Button {
                endConversation()
            } label: {
                topActionCard(icon: "power", title: "End conversation", iconColor: Color.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private func topActionCard(icon: String, title: String, iconColor: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var listeningVisualizer: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.78, blue: 0.72).opacity(0.5))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(Color(red: 0.78, green: 0.72, blue: 0.95).opacity(0.45))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(Color(red: 0.55, green: 0.45, blue: 0.82))
                    .frame(width: 72, height: 72)
            }

            if conversationPhase == .listening {
                Text("EmBeLife is listening...")
                    .font(.body.weight(.medium))
                    .foregroundStyle(statusGray)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var userMessageBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 40)

            VStack(alignment: .trailing, spacing: 4) {
                Text(VoiceNoteSample.userTranscript)
                    .font(.body)
                    .foregroundStyle(Theme.darkText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(userBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(VoiceNoteSample.userTime)
                    .font(.caption2)
                    .foregroundStyle(Color(red: 0.55, green: 0.40, blue: 0.65))
            }

            Image(systemName: "waveform")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Theme.brandOrange)
                .clipShape(Circle())
        }
    }

    private var audioPlaybackCard: some View {
        HStack(spacing: 12) {
            waveformBars
                .frame(maxWidth: .infinity)

            Text(VoiceNoteSample.audioDuration)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.brandOrange)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var waveformBars: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<24, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Theme.brandOrange, Color(red: 0.65, green: 0.45, blue: 0.85)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: barHeight(for: index))
            }
        }
        .frame(height: 36)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [8, 14, 22, 28, 20, 32, 24, 18, 30, 16, 26, 12, 28, 20, 34, 18, 24, 30, 14, 22, 28, 16, 20, 12]
        return pattern[index % pattern.count]
    }

    private var translateButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                conversationPhase = .aiReply
            }
        } label: {
            Text("Translate to text")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(conversationPhase == .playback ? 1 : 0)
        .disabled(conversationPhase != .playback)
    }

    private var aiReplySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                brandMark(size: 32)

                audioPlaybackCard
            }

            HStack {
                Text(VoiceNoteSample.assistantReply)
                    .font(.body)
                    .foregroundStyle(Theme.darkText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(aiBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Spacer(minLength: 40)
            }
            .padding(.leading, 42)
        }
    }

    private var conversationBottomBar: some View {
        HStack(spacing: 12) {
            brandMark(size: 40)

            Button {
                // More options placeholder
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Theme.grayscale70)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(pageBG)
    }

    // MARK: - Shared

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hi, 👋")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.darkText)

            Text("Welcome to")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.darkText)

            emBeLifeLogo
        }
    }

    private var emBeLifeLogo: some View {
        HStack(spacing: 4) {
            Text("Em")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.brandOrange)
                .clipShape(Circle())

            HStack(spacing: 0) {
                Text("Be")
                    .foregroundStyle(Theme.brandOrange)
                Text("Life")
                    .foregroundStyle(Theme.brandOrange)
            }
            .font(.system(size: 28, weight: .bold))

            Text("™")
                .font(.caption)
                .foregroundStyle(Theme.brandOrange)
                .offset(y: -8)
        }
    }

    private func brandMark(size: CGFloat) -> some View {
        Image(systemName: "sparkles")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.brandOrange)
            .clipShape(Circle())
    }

    private var orangeStatusBar: some View {
        Theme.brandOrange
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
    }

    private var typeInputSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Type your message")
                    .font(.headline)
                    .foregroundStyle(Theme.darkText)

                TextField("What are you looking for?", text: $typedInput, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Theme.inputFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("Send") {
                    showTypeSheet = false
                    if screenPhase != .conversation {
                        startConversation()
                    }
                    conversationPhase = .userTranscript
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation { conversationPhase = .playback }
                    }
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
                .disabled(typedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showTypeSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func startConversation() {
        withAnimation(.easeInOut(duration: 0.25)) {
            screenPhase = .conversation
            conversationPhase = .listening
            isPlaying = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard screenPhase == .conversation, conversationPhase == .listening else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                conversationPhase = .userTranscript
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            guard screenPhase == .conversation, conversationPhase == .userTranscript else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                conversationPhase = .playback
                isPlaying = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard screenPhase == .conversation, conversationPhase == .playback else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                conversationPhase = .aiReply
                isPlaying = false
            }
        }
    }

    private func endConversation() {
        withAnimation(.easeInOut(duration: 0.25)) {
            screenPhase = .ready
            conversationPhase = .listening
            isPlaying = false
            typedInput = ""
        }
    }
}

#Preview {
    NotesView()
        .environment(AppModel())
}
