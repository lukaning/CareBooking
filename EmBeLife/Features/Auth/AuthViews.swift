import SwiftUI

enum AuthRoute: Hashable {
    case signUp
    case enterCode(email: String, name: String)
    case forgotPassword
    case createNewPassword
}

struct AuthFlowView: View {
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            SignInView(path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .signUp:
                        SignUpView(path: $path)
                    case .enterCode(let email, let name):
                        EnterCodeView(path: $path, email: email, name: name)
                    case .forgotPassword:
                        ForgotPasswordView(path: $path)
                    case .createNewPassword:
                        CreateNewPasswordView(path: $path)
                    }
                }
        }
    }
}

// MARK: - Shared chrome

struct AuthHeader: View {
    let title: String
    let headline: String
    let subtitle: String
    var onBack: (() -> Void)?
    /// When true, shows the circular back control even if `onBack` is nil (visual match for root Sign In).
    var showsBackControl = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                HStack {
                    if showsBackControl || onBack != nil {
                        AuthBackButton(action: onBack ?? {})
                    }
                    Spacer()
                }
            }
            .padding(.top, 4)

            Text(headline)
                .font(.scaledSystem(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
    }
}

struct AuthBackButton: View {
    var action: (() -> Void)?
    var tint: Color = .white
    var background: Color = .white.opacity(0.2)

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(background)
                .clipShape(Circle())
        }
        .opacity(action == nil ? 0 : 1)
        .disabled(action == nil)
        .buttonStyle(.plain)
    }
}

struct SocialSignInRow: View {
    @Environment(AppModel.self) private var appModel
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Theme.grayscale60.opacity(0.35))
                    .frame(height: 1)
                Text("Or Sign In with")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.grayscale60)
                    .fixedSize()
                Rectangle()
                    .fill(Theme.grayscale60.opacity(0.35))
                    .frame(height: 1)
            }

            HStack(spacing: 16) {
                socialButton(image: "googleLogo") {
                    await authenticate(provider: .google)
                }
                socialButton(image: "appleLogo") {
                    await authenticate(provider: .apple)
                }
            }
            .opacity(isBusy ? 0.55 : 1)
            .disabled(isBusy)
        }
        .alert("Sign-in failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private enum Provider {
        case google
        case apple
    }

    private func socialButton(image: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .frame(width: 72, height: 52)
                .background(Theme.inputFill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func authenticate(provider: Provider) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            let profile: SocialAuthProfile
            switch provider {
            case .google:
                profile = try await SocialAuthService.shared.signInWithGoogle()
            case .apple:
                profile = try await SocialAuthService.shared.signInWithApple()
            }
            appModel.completeSignIn(email: profile.email, name: profile.name)
        } catch let error as SocialAuthError {
            if case .cancelled = error { return }
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TermsFooter: View {
    var body: some View {
        Text("By signing up you agree to our ")
            .foregroundStyle(Theme.grayscale70)
        + Text("Terms")
            .foregroundStyle(Theme.darkText)
            .fontWeight(.semibold)
        + Text(" and ")
            .foregroundStyle(Theme.grayscale70)
        + Text("Conditions of Use")
            .foregroundStyle(Theme.darkText)
            .fontWeight(.semibold)
    }
}

/// White form sheet that sits under the orange auth header (Figma: white lower half, rounded top).
private struct AuthFormSheet<Content: View>: View {
    var topPadding: CGFloat = 28
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 24)
                .padding(.top, topPadding)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
        .offset(y: -20)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}

private struct PlainAuthScreen<Content: View>: View {
    var onBack: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                AuthBackButton(
                    action: onBack,
                    tint: Theme.darkText,
                    background: Theme.inputFill
                )
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Sign In

struct SignInView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var path: [AuthRoute]

    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false

    var body: some View {
        VStack(spacing: 0) {
            AuthHeader(
                title: "Sign In",
                headline: "Hi, Welcome Back! 👋",
                subtitle: "Lorem ipsum dolor sit amet, consectetur",
                onBack: { appModel.showWelcome() },
                showsBackControl: true
            )

            AuthFormSheet(topPadding: 52) {
                VStack(alignment: .leading, spacing: 20) {
                    AuthTextField(title: "Email Address", placeholder: "Enter your email address", text: $email)
                    AuthTextField(title: "Password", placeholder: "Enter your password", text: $password, isSecure: true)

                    HStack {
                        Button {
                            rememberMe.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: rememberMe ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(rememberMe ? Theme.brandOrange : Theme.grayscale60)
                                    .font(.title3)
                                Text("Remember Me")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.grayscale70)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button("Forgot Password") {
                            path.append(.forgotPassword)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.errorCoral)
                    }

                    Button("Sign In") {
                        appModel.completeSignIn(email: email.isEmpty ? "user@example.com" : email)
                    }
                    .buttonStyle(PrimaryOrangeButtonStyle())
                    .padding(.top, 4)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(Theme.grayscale70)
                        Button("Sign Up") {
                            path.append(.signUp)
                        }
                        .foregroundStyle(Theme.linkBlue)
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)

                    SocialSignInRow()
                        .padding(.top, 8)

                    TermsFooter()
                        .font(.footnote.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Sign Up

struct SignUpView: View {
    @Binding var path: [AuthRoute]

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 0) {
            AuthHeader(
                title: "Sign Up",
                headline: "Create Account",
                subtitle: "Lorem ipsum dolor sit amet, consectetur",
                onBack: { path.removeLast() }
            )

            AuthFormSheet {
                VStack(alignment: .leading, spacing: 18) {
                    AuthTextField(title: "Full Name", placeholder: "Enter your name", text: $fullName)
                    AuthTextField(title: "E-mail", placeholder: "Enter your email", text: $email)
                    AuthTextField(title: "Password", placeholder: "Enter your password", text: $password, isSecure: true)

                    Button("Create An Account") {
                        let resolvedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        let resolvedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                        path.append(
                            .enterCode(
                                email: resolvedEmail.isEmpty ? "example@gmail.com" : resolvedEmail,
                                name: resolvedName.isEmpty ? "Alex" : resolvedName
                            )
                        )
                    }
                    .buttonStyle(PrimaryOrangeButtonStyle())
                    .padding(.top, 8)

                    SocialSignInRow()
                        .padding(.top, 12)

                    TermsFooter()
                        .font(.footnote.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Enter Code (sign-up verification)

struct EnterCodeView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var path: [AuthRoute]
    let email: String
    let name: String

    @State private var digits = ["", "", "", ""]
    @State private var showTerms = false
    @FocusState private var focusedIndex: Int?

    private var codeComplete: Bool {
        digits.allSatisfy { $0.count == 1 }
    }

    var body: some View {
        PlainAuthScreen(onBack: { path.removeLast() }) {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Enter Code")
                        .font(.scaledSystem(size: 28, weight: .bold))
                        .foregroundStyle(Theme.darkText)

                    Text("We have just sent you 4 digit code via your email \(email)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale70)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 36)

                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { index in
                        codeBox(index)
                    }
                }
                .padding(.top, 8)

                Button("Create An Account") {
                    showTerms = true
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
                .disabled(!codeComplete)
                .opacity(codeComplete ? 1 : 0.55)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                HStack(spacing: 4) {
                    Text("Didn't receive code?")
                        .foregroundStyle(Theme.grayscale70)
                    Button("Resend Code") {
                        digits = ["", "", "", ""]
                        focusedIndex = 0
                    }
                    .foregroundStyle(Theme.linkBlue)
                }
                .font(.subheadline.weight(.semibold))

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focusedIndex = 0 }
        .overlay {
            if showTerms {
                TermsAgreementOverlay(
                    onDisagree: { showTerms = false },
                    onAgree: {
                        showTerms = false
                        appModel.completeSignUp(name: name, email: email)
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showTerms)
    }

    private func codeBox(_ index: Int) -> some View {
        let isFocused = focusedIndex == index
        let display = digits[index].isEmpty ? "" : (isFocused ? digits[index] : "•")

        return ZStack {
            Text(display)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            TextField("", text: Binding(
                get: { digits[index] },
                set: { newValue in
                    // Handle paste of full code
                    let numbers = newValue.filter(\.isNumber)
                    if numbers.count > 1 {
                        applyPastedCode(String(numbers))
                        return
                    }
                    let filtered = String(numbers.prefix(1))
                    let previous = digits[index]
                    digits[index] = filtered
                    if !filtered.isEmpty, index < 3 {
                        focusedIndex = index + 1
                    } else if filtered.isEmpty, !previous.isEmpty {
                        // cleared current
                    } else if filtered.isEmpty, index > 0 {
                        focusedIndex = index - 1
                    } else if !filtered.isEmpty {
                        focusedIndex = nil
                    }
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focusedIndex, equals: index)
            .opacity(0.02)
            .frame(width: 64, height: 64)
        }
        .frame(width: 64, height: 64)
        .background(Theme.inputFill)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isFocused ? Theme.linkBlue : .clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { focusedIndex = index }
        .onKeyPress(.delete) {
            if digits[index].isEmpty, index > 0 {
                focusedIndex = index - 1
                digits[index - 1] = ""
                return .handled
            }
            return .ignored
        }
    }

    private func applyPastedCode(_ code: String) {
        let chars = Array(code.prefix(4))
        for i in 0..<4 {
            digits[i] = i < chars.count ? String(chars[i]) : ""
        }
        focusedIndex = chars.count >= 4 ? nil : chars.count
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @Binding var path: [AuthRoute]
    @State private var email = ""

    var body: some View {
        PlainAuthScreen(onBack: { path.removeLast() }) {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Forgot Password")
                        .font(.scaledSystem(size: 28, weight: .bold))
                        .foregroundStyle(Theme.darkText)

                    Text("Recover your account password")
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale70)
                }
                .padding(.top, 36)

                AuthTextField(title: "E-mail", placeholder: "Enter your email", text: $email)
                    .padding(.horizontal, 24)

                Button("Next") {
                    path.append(.createNewPassword)
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

// MARK: - Create New Password

struct CreateNewPasswordView: View {
    @Binding var path: [AuthRoute]

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showSuccess = false

    private var canContinue: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    var body: some View {
        PlainAuthScreen(onBack: { path.removeLast() }) {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Create a New Password")
                        .font(.scaledSystem(size: 28, weight: .bold))
                        .foregroundStyle(Theme.darkText)
                        .multilineTextAlignment(.center)

                    Text("Enter your new password")
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale70)
                }
                .padding(.top, 36)
                .padding(.horizontal, 24)

                VStack(spacing: 18) {
                    AuthTextField(title: "New Password", placeholder: "Enter new password", text: $newPassword, isSecure: true)
                    AuthTextField(title: "Confirm Password", placeholder: "Confirm your password", text: $confirmPassword, isSecure: true)
                }
                .padding(.horizontal, 24)

                Button("Next") {
                    showSuccess = true
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.55)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .overlay {
            if showSuccess {
                PasswordSuccessOverlay {
                    showSuccess = false
                    path.removeAll()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSuccess)
    }
}

// MARK: - Overlays

private struct TermsAgreementOverlay: View {
    var onDisagree: () -> Void
    var onAgree: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDisagree)

            VStack(spacing: 24) {
                Text("I agree to the Terms of Service and Conditions of Use including consent to electronic communications and I affirm that the information provided is my own.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.darkText)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 16) {
                    Button("Disagree", action: onDisagree)
                        .font(.headline)
                        .foregroundStyle(Theme.errorCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)

                    Button("Agree", action: onAgree)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
            .padding(.horizontal, 28)
        }
    }
}

private struct PasswordSuccessOverlay: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.90, green: 0.95, blue: 1.0))
                        .frame(width: 120, height: 120)

                    Image(systemName: "hand.thumbsup.fill")
                        .font(.scaledSystem(size: 48))
                        .foregroundStyle(Theme.brandOrange)
                }

                Text("Success")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.darkText)

                Text("Your password is successfully created")
                    .font(.subheadline)
                    .foregroundStyle(Theme.grayscale70)
                    .multilineTextAlignment(.center)

                Button("Continue", action: onContinue)
                    .buttonStyle(PrimaryOrangeButtonStyle())
                    .padding(.top, 4)
            }
            .padding(28)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
            .padding(.horizontal, 36)
        }
    }
}
