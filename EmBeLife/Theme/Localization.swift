import SwiftUI

/// Localizes `key` with the current SwiftUI locale, including inline markdown (`**bold**`).
struct LocalizedMarkdownText: View {
    @Environment(\.locale) private var locale
    let key: String

    var body: some View {
        let value = String(
            localized: LocalizedStringResource(
                String.LocalizationValue(stringLiteral: key),
                locale: locale
            )
        )
        if let attributed = try? AttributedString(
            markdown: value,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
        } else {
            Text(value)
        }
    }
}
