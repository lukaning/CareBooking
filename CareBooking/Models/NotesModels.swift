import Foundation

enum NotesScreenPhase: Equatable {
    case welcome
    case ready
    case conversation
}

enum VoiceConversationPhase: Equatable {
    case listening
    case userTranscript
    case playback
    case aiReply
}

struct VoiceNoteMessage: Identifiable, Hashable {
    enum Role: Hashable {
        case user
        case assistant
    }

    var id: String
    var role: Role
    var text: String
    var timeLabel: String
    var showsWaveform: Bool
}

enum VoiceNoteSample {
    static let userTranscript = "hi, im looking for child care for my kid..."
    static let assistantReply = "I got it, let me look for some options for you"
    static let userTime = "08:33"
    static let audioDuration = "0:08"
}
