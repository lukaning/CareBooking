import SwiftUI
import UIKit

enum Theme {
    static let brandOrange = Color("BrandOrange")
    static let inputFill = Color("InputFill")
    static let linkBlue = Color("LinkBlue")
    static let errorCoral = Color("ErrorCoral")
    static let grayscale70 = Color(red: 0.471, green: 0.510, blue: 0.541)
    static let grayscale60 = Color(red: 0.612, green: 0.643, blue: 0.671)
    static let darkText = Color(red: 0.055, green: 0.067, blue: 0.102)
    static let mutedText = Color(red: 0.576, green: 0.576, blue: 0.667)
    static let cardBorder = Color(red: 0.937, green: 0.937, blue: 0.953)
    static let profilePill = Color(red: 0.941, green: 0.957, blue: 0.976)
    static let segmentBG = Color(red: 0.941, green: 0.957, blue: 0.976)
}

extension Font {
    /// SF system font that scales with the user's Dynamic Type / Text Size setting.
    static func scaledSystem(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle? = nil
    ) -> Font {
        let style = textStyle ?? preferredTextStyle(for: size)
        let base = UIFont.systemFont(ofSize: size, weight: weight.uiKitWeight)
        let scaled = UIFontMetrics(forTextStyle: style.uiKitTextStyle).scaledFont(for: base)
        return Font(scaled)
    }

    private static func preferredTextStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ...11: .caption2
        case ...13: .caption
        case ...15: .subheadline
        case ...17: .callout
        case ...20: .body
        case ...24: .title3
        case ...28: .title2
        case ...34: .title
        default: .largeTitle
        }
    }
}

private extension Font.Weight {
    var uiKitWeight: UIFont.Weight {
        switch self {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        default: .regular
        }
    }
}

private extension Font.TextStyle {
    var uiKitTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}

/// Full-width hero image at 16:9 aspect ratio.
struct HeroHeaderImage: View {
    private static let aspectRatio: CGFloat = 16 / 9

    var body: some View {
        Color.clear
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay {
                Image("onboardingHero")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .frame(maxWidth: .infinity)
    }
}

struct PrimaryOrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            // Match PrimaryBlackButtonStyle / "Get Started" control height.
            .padding(.vertical, 18)
            .background(Theme.brandOrange.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PrimaryBlackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.black.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Horizontal wrapping layout for chip/tag rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

struct EmBeLifeLogo: View {
    var markSize: CGFloat = 44
    var wordSize: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Text("Em")
                .font(.scaledSystem(size: markSize * 0.38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: markSize, height: markSize)
                .background(Theme.brandOrange)
                .clipShape(Circle())

            HStack(alignment: .top, spacing: 0) {
                Text("BeLife")
                    .font(.scaledSystem(size: wordSize, weight: .semibold))
                    .foregroundStyle(Theme.brandOrange)

                Text("™")
                    .font(.scaledSystem(size: wordSize * 0.38, weight: .medium))
                    .foregroundStyle(Theme.brandOrange)
                    .padding(.top, 2)
            }
        }
    }
}

struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.grayscale70)

            HStack {
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .textInputAutocapitalization(isSecure ? .never : .words)
                            .keyboardType(title.lowercased().contains("mail") ? .emailAddress : .default)
                            .autocorrectionDisabled(title.lowercased().contains("mail"))
                    }
                }
                .font(.body)

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye" : "eye.slash.fill")
                            .foregroundStyle(Theme.grayscale60)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.inputFill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
