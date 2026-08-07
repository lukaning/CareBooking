import SwiftUI

// MARK: - Shared gift chrome

private enum GiftChrome {
    static let orange = Theme.brandOrange
    static let card = Color.white
    static let blush = Color(red: 1.0, green: 0.96, blue: 0.95)
    static let muted = Color(red: 0.45, green: 0.48, blue: 0.55)
    static let fieldLabel = Color(red: 0.10, green: 0.20, blue: 0.45)
    static let rowBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    static let selectedFill = Color(red: 1.0, green: 0.847, blue: 0.796)
    static let brandBlue = Color(red: 0.141, green: 0.420, blue: 0.992)
    static let radioRing = Color(red: 0.70, green: 0.72, blue: 0.76)
    static let rowTitle = Color(red: 0.200, green: 0.220, blue: 0.247)
}

private struct GiftOrangeScreen<Content: View>: View {
    let title: String
    var showsBack: Bool = true
    var onBack: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            GiftChrome.orange.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    HStack {
                        if showsBack {
                            Button {
                                onBack?()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct GiftWhiteCard<Content: View>: View {
    var fill: Color = GiftChrome.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fill)
            )
            .padding(.horizontal, 16)
    }
}

/// Party-popper style celebration for success / received screens.
struct GiftCelebrationIllustration: View {
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Capsule()
                    .fill(confettiColor(i))
                    .frame(width: 6, height: 14)
                    .rotationEffect(.degrees(Double(i) * 32))
                    .offset(x: cos(Double(i)) * 52, y: -48 - sin(Double(i)) * 18)
            }

            Image(systemName: "party.popper.fill")
                .font(.system(size: 64))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    Color(red: 0.25, green: 0.45, blue: 0.95),
                    Color(red: 0.55, green: 0.40, blue: 0.95)
                )
                .offset(y: 8)
        }
        .frame(height: 120)
        .accessibilityHidden(true)
    }

    private func confettiColor(_ i: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.45, green: 0.55, blue: 1.0),
            Color(red: 0.55, green: 0.35, blue: 0.95),
            Color(red: 0.25, green: 0.55, blue: 0.95),
            Color(red: 0.65, green: 0.45, blue: 1.0)
        ]
        return colors[i % colors.count]
    }
}

// MARK: - Experience 1: Confirm gift

struct GiftConfirmView: View {
    @Bindable var draft: GiftDraft
    @Binding var path: [GiftExperienceRoute]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GiftOrangeScreen(title: "Gift to EmBeLife", onBack: { dismiss() }) {
            ScrollView {
                GiftWhiteCard(fill: GiftChrome.blush) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Theme.brandOrange)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "bag.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text(draft.recipientLabel)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(GiftChrome.muted)
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundStyle(GiftChrome.muted)
                                }
                                Text(draft.amountLabel)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Theme.darkText)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gift out")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Theme.darkText)

                            Text(draft.amountLabel)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(Theme.darkText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Text("Immediately arrive to the embelife account, support ACH, Venmo, paypal, credit card, etc")
                                .font(.subheadline)
                                .foregroundStyle(GiftChrome.muted)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Button {
                            path.append(.paymentMethod)
                        } label: {
                            HStack(spacing: 12) {
                                if let logo = draft.primaryLogoAsset {
                                    Image(logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 22)
                                        .frame(width: 36, alignment: .leading)
                                } else {
                                    Image(systemName: "building.columns.fill")
                                        .font(.body)
                                        .foregroundStyle(Theme.brandOrange)
                                        .frame(width: 36)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Payment Method")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(GiftChrome.muted)
                                    Text(draft.paymentMethodSummaryTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                    Text(draft.paymentMethodSummarySubtitle)
                                        .font(.caption)
                                        .foregroundStyle(GiftChrome.muted)
                                }

                                Spacer(minLength: 4)

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(draft.paymentDeliveryLabel)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(GiftChrome.muted)
                                        .multilineTextAlignment(.trailing)
                                    Text(draft.paymentFeeLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(GiftChrome.muted)
                            }
                            .padding(14)
                            .background(Color(red: 0.95, green: 0.96, blue: 0.97))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            path.append(.sent)
                        } label: {
                            Text("Confirm Gift")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.brandOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Experience 2: Payment method

struct GiftPaymentMethodView: View {
    @Bindable var draft: GiftDraft
    @Binding var path: [GiftExperienceRoute]
    @Environment(\.dismiss) private var dismiss

    private let selectionAnimation = Animation.easeInOut(duration: 0.28)

    var body: some View {
        GiftOrangeScreen(title: "Payment method", onBack: { path.removeLast() }) {
            ScrollView {
                GiftWhiteCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Payment Method")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.darkText)

                        ForEach(GiftDraft.giftPaymentMethods, id: \.self) { method in
                            methodCard(method)
                        }
                    }
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func methodCard(_ method: PaymentMethodKind) -> some View {
        let isSelected = draft.selectedMethod == method

        return VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(selectionAnimation) {
                    draft.selectedMethod = method
                }
            } label: {
                HStack(spacing: 12) {
                    radio(isSelected: isSelected)
                    Text(method.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isSelected ? GiftChrome.brandBlue : GiftChrome.rowTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        ForEach(method.logoAssetNames, id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .frame(height: name.contains("Visa") || name == "payVisa" ? 14 : 18)
                                .frame(maxWidth: 40)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected {
                expandedFields(for: method)
            }
        }
        .padding(14)
        .background(isSelected ? GiftChrome.selectedFill : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Theme.brandOrange : GiftChrome.rowBorder, lineWidth: isSelected ? 1.5 : 1)
        )
    }

    @ViewBuilder
    private func expandedFields(for method: PaymentMethodKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            switch method {
            case .bankAccount:
                field("Account Holder Name", text: $draft.bankDetails.accountHolderName)
                field("Account Number", text: $draft.bankDetails.accountNumber)
                field("ABA Routing Number", text: $draft.bankDetails.abaRoutingNumber)
            case .zelle:
                field("Email or Mobile phone number", text: $draft.zelleDetails.contact)
            case .venmo:
                field("Venmo username or phone", text: $draft.venmoDetails.contact)
            case .paypal:
                field("PayPal email", text: $draft.paypalDetails.contact)
            case .creditCard:
                field("Cardholder Name", text: $draft.creditCardDetails.cardholderName)
                field("Card Number", text: $draft.creditCardDetails.cardNumber)
                HStack(spacing: 12) {
                    field("Expiry", text: $draft.creditCardDetails.expiry)
                    field("CVC", text: $draft.creditCardDetails.cvc)
                }
            case .giftFund:
                EmptyView()
            }

            Button {
                path.removeLast()
            } label: {
                Text("Confirm")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.brandOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GiftChrome.fieldLabel)
            TextField(title, text: text)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(GiftChrome.rowBorder, lineWidth: 1)
                )
        }
    }

    private func radio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Theme.brandOrange : GiftChrome.radioRing, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            Circle()
                .fill(Theme.brandOrange)
                .frame(width: 12, height: 12)
                .scaleEffect(isSelected ? 1 : 0.001)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Experience 3: Gift sent success

struct GiftSentSuccessView: View {
    @Bindable var draft: GiftDraft
    @Binding var path: [GiftExperienceRoute]

    var body: some View {
        GiftOrangeScreen(title: "Gift to EmBeLife", showsBack: false) {
            GiftWhiteCard {
                VStack(spacing: 18) {
                    GiftCelebrationIllustration()

                    Text("Gift amount \(draft.amountLabel) sent")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.darkText)
                        .multilineTextAlignment(.center)

                    Text("Your gift receiver could see this amount right away in their gift fund wallet")
                        .font(.subheadline)
                        .foregroundStyle(GiftChrome.muted)
                        .multilineTextAlignment(.center)

                    Button {
                        path.append(.signUp)
                    } label: {
                        Text("Create An Account")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.brandOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    SocialSignInRow()
                        .padding(.top, 4)

                    TermsFooter()
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Experience 4: Sign up (from gift)

struct GiftSignUpView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [GiftExperienceRoute]

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 0) {
            AuthHeader(
                title: "Sign Up",
                headline: "Create Account",
                subtitle: "Join EmBeLife to manage gifts, care bookings, and more.",
                onBack: { path.removeLast() },
                showsBackControl: true
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AuthTextField(title: "Full Name", placeholder: "Enter your name", text: $fullName)
                    AuthTextField(title: "E-mail", placeholder: "Enter your email", text: $email)
                    AuthTextField(title: "Password", placeholder: "Enter your password", text: $password, isSecure: true)

                    Button {
                        finishSignUp()
                    } label: {
                        Text("Create An Account")
                    }
                    .buttonStyle(PrimaryOrangeButtonStyle())
                    .padding(.top, 4)
                    .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty
                        || email.trimmingCharacters(in: .whitespaces).isEmpty
                        || password.isEmpty)
                    .opacity(fullName.isEmpty || email.isEmpty || password.isEmpty ? 0.55 : 1)

                    SocialSignInRow()
                        .padding(.top, 8)

                    TermsFooter()
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
            .offset(y: -20)
            .background(Color.white.ignoresSafeArea(edges: .bottom))
        }
        .background(Theme.brandOrange.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func finishSignUp() {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if appModel.isSignedIn {
            if !name.isEmpty { appModel.userName = name }
            if !mail.isEmpty { appModel.userEmail = mail }
            path = []
        } else {
            appModel.completeSignUp(name: name, email: mail)
        }
    }
}

// MARK: - Experience 5: Receiver claim

struct GiftReceivedView: View {
    @Bindable var draft: GiftDraft
    @Binding var path: [GiftExperienceRoute]
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showBannerDetails = false

    var body: some View {
        ZStack {
            GiftChrome.orange.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    // Top notification card
                    HStack(alignment: .top, spacing: 12) {
                        Capsule()
                            .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                            .frame(width: 6, height: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Gift fund received!")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Theme.darkText)
                                Spacer()
                                Button("Details") {
                                    showBannerDetails = true
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.linkBlue)
                            }
                            Text("\(draft.amountLabel) in total")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(GiftChrome.muted)
                            Text(draft.receivedDateLabel)
                                .font(.caption)
                                .foregroundStyle(GiftChrome.muted)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    GiftWhiteCard {
                        VStack(spacing: 18) {
                            GiftCelebrationIllustration()

                            Text("You got a Gift amount of \(draft.amountLabel) in your EmBeLife account from \(draft.senderDisplayName), create your account now")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Theme.darkText)
                                .multilineTextAlignment(.center)

                            Text("You could see this amount right away in your gift fund wallet after creating account")
                                .font(.subheadline)
                                .foregroundStyle(GiftChrome.muted)
                                .multilineTextAlignment(.center)

                            Button {
                                path.append(.signUp)
                            } label: {
                                Text("Create An Account")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.brandOrange)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            SocialSignInRow()

                            TermsFooter()
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Button {
                    if let onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .alert("Gift Details", isPresented: $showBannerDetails) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(draft.amountLabel) gift from \(draft.senderDisplayName) on \(draft.receivedDateLabel). Funds appear in your gift fund wallet once you create an account.")
        }
    }
}

// MARK: - Destination host

struct GiftExperienceDestination: View {
    let route: GiftExperienceRoute
    @Bindable var draft: GiftDraft
    @Binding var path: [GiftExperienceRoute]

    var body: some View {
        switch route {
        case .confirm:
            GiftConfirmView(draft: draft, path: $path)
        case .paymentMethod:
            GiftPaymentMethodView(draft: draft, path: $path)
        case .sent:
            GiftSentSuccessView(draft: draft, path: $path)
        case .signUp:
            GiftSignUpView(path: $path)
        case .received:
            GiftReceivedView(draft: draft, path: $path)
        }
    }
}
