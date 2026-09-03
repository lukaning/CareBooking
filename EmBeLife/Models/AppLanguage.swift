import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "Spanish"
    case chinese = "Chinese"
    case english = "English"
    case tagalog = "Tagalog"
    case vietnamese = "Vietnamese"
    case korean = "Korean"
    case russian = "Russian"
    case asl = "American Sign Language (ASL)"
    case armenian = "Armenian"
    case persian = "Persian"
    case japanese = "Japanese"
    case french = "French"
    case german = "German"
    case italian = "Italian"

    var id: String { rawValue }

    /// Order shown in the onboarding language dropdown.
    static let pickerOrder: [AppLanguage] = [
        .spanish, .chinese, .english, .tagalog, .vietnamese, .korean, .russian,
        .asl, .armenian, .persian, .japanese, .french, .german, .italian
    ]

    static let pickerNames: [String] = pickerOrder.map(\.rawValue)

    var localeIdentifier: String {
        switch self {
        case .english, .asl: "en"
        case .spanish: "es"
        case .chinese: "zh-Hans"
        case .tagalog: "fil"
        case .vietnamese: "vi"
        case .korean: "ko"
        case .russian: "ru"
        case .armenian: "hy"
        case .persian: "fa"
        case .japanese: "ja"
        case .french: "fr"
        case .german: "de"
        case .italian: "it"
        }
    }

    var locale: Locale { Locale(identifier: localeIdentifier) }

    var layoutDirection: LayoutDirection {
        self == .persian ? .rightToLeft : .leftToRight
    }

    static func from(displayName: String) -> AppLanguage {
        AppLanguage(rawValue: displayName) ?? .english
    }
}

extension String {
    var localizedKey: LocalizedStringKey { LocalizedStringKey(self) }
}
