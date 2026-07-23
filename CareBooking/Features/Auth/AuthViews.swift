import SwiftUI

struct AuthFlowView: View {
    enum Route: Hashable {
        case signIn
        case signUp
    }

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            SignInView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .signIn:
                        SignInView(path: $path)
                    case .signUp:
                        SignUpView(path: $path)
                    }
                }
        }
    }
}

struct AuthHeader: View {
    let title: String
    let headline: String
    let subtitle: String
    var onBack: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                HStack {
                    Button {
                        onBack?()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .opacity(onBack == nil ? 0 : 1)
                    .disabled(onBack == nil)

                    Spacer()
                }
            }
            .padding(.top, 8)

            Text(headline)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.89, green: 0.91, blue: 0.93))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandOrange)
    }
}

struct SocialSignInRow: View {
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
                socialButton(image: "googleLogo")
                socialButton(image: "appleLogo")
            }
        }
    }

    private func socialButton(image: String) -> some View {
        Button {
            // Social auth placeholder for MVP
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

struct SignInView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var path: [AuthFlowView.Route]

    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHeader(
                    title: "Sign In",
                    headline: "Hi, Welcome Back! 👋",
                    subtitle: "Lorem ipsum dolor sit amet, consectetur"
                )

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

                        Button("Forgot Password") {}
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
                .padding(24)
                .background(
                    Color(.systemBackground)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                )
                .offset(y: -16)
            }
        }
        .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
        .scrollIndicators(.hidden)
        .navigationBarHidden(true)
    }
}

struct SignUpView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var path: [AuthFlowView.Route]

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHeader(
                    title: "Sign Up",
                    headline: "Create Account",
                    subtitle: "Lorem ipsum dolor sit amet, consectetur",
                    onBack: { path.removeLast() }
                )

                VStack(alignment: .leading, spacing: 18) {
                    AuthTextField(title: "Full Name", placeholder: "Enter your name", text: $fullName)
                    AuthTextField(title: "E-mail", placeholder: "Enter your email", text: $email)
                    AuthTextField(title: "Password", placeholder: "Enter your password", text: $password, isSecure: true)

                    Button("Create An Account") {
                        appModel.completeSignUp(
                            name: fullName.isEmpty ? "Alex" : fullName,
                            email: email.isEmpty ? "user@example.com" : email
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
                .padding(24)
                .background(
                    Color(.systemBackground)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                )
                .offset(y: -16)
            }
        }
        .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
        .scrollIndicators(.hidden)
        .navigationBarHidden(true)
    }
}
