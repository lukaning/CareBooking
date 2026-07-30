import SwiftUI

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

/// Full-width hero image preserving the asset's 3:2 aspect ratio.
struct HeroHeaderImage: View {
    private static let aspectRatio: CGFloat = 1000 / 667

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
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
