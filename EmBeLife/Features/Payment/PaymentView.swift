import SwiftUI

struct PaymentView: View {
    @State private var segment: PaymentSegment = .paymentMethod
    @State private var selectedMethod: PaymentMethodKind? = .defaultMethod
    @State private var bankDetails = BankAccountDetails.sample
    @State private var zelleDetails = ContactPaymentDetails.zelleSample
    @State private var venmoDetails = ContactPaymentDetails.venmoSample
    @State private var paypalDetails = ContactPaymentDetails.paypalSample
    @State private var creditCardDetails = CreditCardDetails.sample
    @State private var showSendGiftMenu = false
    @State private var showGiftInfo = false
    @State private var showBookingsInfo = false
    @State private var giftActionMessage: String?
    @State private var confirmMessage: String?
    @State private var giftPath: [GiftExperienceRoute] = []
    @State private var giftDraft = GiftDraft()

    private let giftBalance = 240
    private let giftOutTotal = 24
    private let completedBookings = 5
    private let transactions = PaymentTransaction.samples
    private let defaultMethod = PaymentMethodKind.defaultMethod

    private let summaryCardBG = Color(red: 0.988, green: 0.988, blue: 0.988)
    private let segmentTrack = Color(red: 0.941, green: 0.957, blue: 0.976)
    private let giftIconBG = Color(red: 0.941, green: 0.361, blue: 0.267)
    private let serviceIconBG = Color(red: 0.969, green: 0.698, blue: 0.420)
    private let sendGiftTint = Color(red: 0.141, green: 0.420, blue: 0.992).opacity(0.08)
    private let sendGiftArrow = Color(red: 0.141, green: 0.420, blue: 0.992)
    private let typeABadge = Color(red: 0.710, green: 0.894, blue: 0.792)
    private let typeBBadge = Color(red: 1.0, green: 0.737, blue: 0.600)
    private let mutedLabel = Color(red: 0.435, green: 0.463, blue: 0.494)
    private let rowTitle = Color(red: 0.200, green: 0.220, blue: 0.247)
    private let cardFill = Color(red: 0.957, green: 0.957, blue: 0.957).opacity(0.5)
    private let brandBlue = Color(red: 0.141, green: 0.420, blue: 0.992)
    private let rowBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let radioRing = Color(red: 0.70, green: 0.72, blue: 0.76)
    private let linkGray = Color(red: 0.45, green: 0.48, blue: 0.55)
    private let selectedMethodFill = Color(red: 1.0, green: 0.847, blue: 0.796)
    private let fieldLabel = Color(red: 0.10, green: 0.20, blue: 0.45)
    private let giftSummaryBar = Color(red: 0.93, green: 0.94, blue: 0.96)
    private let selectionAnimation = Animation.easeInOut(duration: 0.28)

    var body: some View {
        NavigationStack(path: $giftPath) {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    segmentControl
                    Group {
                        switch segment {
                        case .paymentMethod:
                            paymentMethodsSection
                        case .transactions:
                            transactionsList
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .background(Color.white)
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .background {
                if showSendGiftMenu {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showSendGiftMenu = false
                            }
                        }
                }
            }
            .alert("Gift Balance", isPresented: $showGiftInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Gift funds can be sent to providers or received from friends and family.")
            }
            .alert("Bookings Completed", isPresented: $showBookingsInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Counts care visits you have completed through EmBeLife.")
            }
            .alert("Send Gift", isPresented: Binding(
                get: { giftActionMessage != nil },
                set: { if !$0 { giftActionMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(giftActionMessage ?? "")
            }
            .alert("Payment Method", isPresented: Binding(
                get: { confirmMessage != nil },
                set: { if !$0 { confirmMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(confirmMessage ?? "")
            }
            .navigationDestination(for: GiftExperienceRoute.self) { route in
                GiftExperienceDestination(route: route, draft: giftDraft, path: $giftPath)
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                Circle()
                    .fill(giftIconBG)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "gift.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Gift Balance")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(mutedLabel)
                        Button {
                            showGiftInfo = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(mutedLabel)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("$\(giftBalance)")
                        .font(.scaledSystem(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.darkText)
                }

                Spacer(minLength: 8)

                sendGiftButton
            }
            .zIndex(2)

            Rectangle()
                .fill(Color(red: 0.937, green: 0.937, blue: 0.937))
                .frame(height: 1)
                .zIndex(0)

            HStack(alignment: .center, spacing: 14) {
                Circle()
                    .fill(serviceIconBG)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "diamond.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Number of Bookings Completed")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(mutedLabel)
                            .lineLimit(2)
                        Button {
                            showBookingsInfo = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(mutedLabel)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("\(completedBookings) times")
                        .font(.scaledSystem(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.darkText)
                }

                Spacer(minLength: 0)
            }
            .zIndex(0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(summaryCardBG)
                .shadow(color: .black.opacity(0.04), radius: 10, y: 2)
        )
        // Keep the Send Gift menu above neighboring content.
        .zIndex(showSendGiftMenu ? 2 : 0)
    }

    private var sendGiftButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                showSendGiftMenu.toggle()
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .font(.body.weight(.bold))
                    .foregroundStyle(sendGiftArrow)
                    .frame(width: 40, height: 40)
                    .background(sendGiftTint)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text("Send Gift")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.212, green: 0.247, blue: 0.349))
            }
        }
        .buttonStyle(.plain)
        .background(alignment: .topTrailing) {
            if showSendGiftMenu {
                sendGiftMenu
                    // Anchor trailing edge to the action control; keep under the button.
                    .padding(.top, 58)
                    .fixedSize()
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
            }
        }
    }

    private var sendGiftMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SendGiftAction.allCases) { action in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSendGiftMenu = false
                    }
                    handleSendGiftAction(action)
                } label: {
                    HStack(spacing: 10) {
                        sendGiftActionIcon(action)
                            .frame(width: 20, height: 20)

                        Text(action.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.darkText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if action != SendGiftAction.allCases.last {
                    Divider()
                        .background(Color(red: 0.90, green: 0.91, blue: 0.93))
                        .padding(.leading, 44)
                }
            }
        }
        .frame(width: 168)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        .compositingGroup()
    }

    @ViewBuilder
    private func sendGiftActionIcon(_ action: SendGiftAction) -> some View {
        if let asset = action.assetImageName {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Theme.darkText)
        } else if let system = action.systemImage {
            Image(systemName: system)
                .font(.body)
                .foregroundStyle(Theme.darkText)
        }
    }

    private func handleSendGiftAction(_ action: SendGiftAction) {
        switch action {
        case .giftAmount:
            giftDraft = GiftDraft()
            giftPath = [.confirm]
        case .receiveGift:
            giftDraft = GiftDraft()
            giftPath = [.received]
        case .giftService:
            giftActionMessage = "\(action.rawValue) flow coming soon."
        }
    }

    // MARK: - Segment

    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(PaymentSegment.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        segment = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(segment == item ? .semibold : .regular))
                        .foregroundStyle(segment == item ? Theme.darkText : Color(red: 0.396, green: 0.471, blue: 0.557))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if segment == item {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Payment methods

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payment Method")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.darkText)

            VStack(spacing: 10) {
                ForEach(PaymentMethodKind.allCases) { method in
                    paymentMethodCard(method)
                }
            }

            poweredByFooter
                .padding(.top, 4)
        }
    }

    private func paymentMethodCard(_ method: PaymentMethodKind) -> some View {
        let isSelected = selectedMethod == method
        let isDefault = method == defaultMethod

        return VStack(alignment: .leading, spacing: isSelected ? 14 : 0) {
            Button {
                withAnimation(selectionAnimation) {
                    if selectedMethod == method {
                        selectedMethod = nil
                    } else {
                        selectedMethod = method
                    }
                }
            } label: {
                // Keep radio, title, badge, and logos in one compositing group so
                // press + selection motion moves them together.
                HStack(alignment: .center, spacing: 12) {
                    selectionRadio(isSelected: isSelected)

                    HStack(spacing: 8) {
                        Text(method.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(isSelected ? brandBlue : rowTitle)
                            .multilineTextAlignment(.leading)

                        if isDefault {
                            defaultBadge
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    trailingAccessory(for: method)
                        .opacity(isSelected ? 1 : 0.92)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
                .compositingGroup()
            }
            .buttonStyle(PaymentMethodRowButtonStyle())

            expandedDetails(for: method)
                .frame(maxHeight: isSelected ? nil : 0, alignment: .top)
                .opacity(isSelected ? 1 : 0)
                .clipped()
                .allowsHitTesting(isSelected)
                .accessibilityHidden(!isSelected)
        }
        .padding(14)
        .background(isSelected ? selectedMethodFill : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Theme.brandOrange : rowBorder, lineWidth: isSelected ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        .animation(selectionAnimation, value: isSelected)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel(for: method, isSelected: isSelected, isDefault: isDefault))
    }

    @ViewBuilder
    private func expandedDetails(for method: PaymentMethodKind) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            switch method {
            case .bankAccount:
                paymentTextField(title: "Account Holder Name", text: $bankDetails.accountHolderName)
                paymentTextField(title: "Account Number", text: $bankDetails.accountNumber)
                paymentTextField(title: "ABA Routing Number", text: $bankDetails.abaRoutingNumber)
                confirmButton(for: method)

            case .zelle:
                paymentTextField(title: "Email or Mobile phone number", text: $zelleDetails.contact)
                confirmButton(for: method)

            case .venmo:
                paymentTextField(title: "Venmo username or phone", text: $venmoDetails.contact)
                confirmButton(for: method)

            case .paypal:
                paymentTextField(title: "PayPal email", text: $paypalDetails.contact)
                confirmButton(for: method)

            case .giftFund:
                giftFundDetails
                confirmButton(for: method)

            case .creditCard:
                paymentTextField(title: "Cardholder Name", text: $creditCardDetails.cardholderName)
                paymentTextField(title: "Card Number", text: $creditCardDetails.cardNumber)
                HStack(spacing: 12) {
                    paymentTextField(title: "Expiry", text: $creditCardDetails.expiry)
                    paymentTextField(title: "CVC", text: $creditCardDetails.cvc)
                }
                confirmButton(for: method)
            }
        }
    }

    private var giftFundDetails: some View {
        VStack(spacing: 14) {
            Text("$\(giftBalance)")
                .font(.scaledSystem(size: 36, weight: .bold))
                .foregroundStyle(Theme.darkText)
                .frame(maxWidth: .infinity)

            Text("Gift out total amount: $\(giftOutTotal)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(rowTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(giftSummaryBar)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func paymentTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(fieldLabel)

            TextField(title, text: text)
                .font(.body)
                .foregroundStyle(Theme.darkText)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(rowBorder, lineWidth: 1)
                )
        }
    }

    private func confirmButton(for method: PaymentMethodKind) -> some View {
        Button {
            confirmMessage = "\(method.title) confirmed."
        } label: {
            Text("Confirm")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.brandOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func selectionRadio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Theme.brandOrange : radioRing, lineWidth: 1.5)
                .frame(width: 22, height: 22)

            Circle()
                .fill(Theme.brandOrange)
                .frame(width: 12, height: 12)
                // Keep the fill in the hierarchy so it interpolates with the same
                // card expand/collapse animation instead of insert/remove snaps.
                .scaleEffect(isSelected ? 1 : 0.001)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 24, height: 24)
    }

    private var defaultBadge: some View {
        Text("Default")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.brandOrange)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.brandOrange.opacity(0.12))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func trailingAccessory(for method: PaymentMethodKind) -> some View {
        switch method {
        case .bankAccount:
            EmptyView()
        case .giftFund:
            Text("$\(giftBalance)")
                .font(.body.weight(.semibold))
                .foregroundStyle(brandBlue)
        case .zelle, .venmo, .paypal, .creditCard:
            HStack(spacing: 6) {
                ForEach(method.logoAssetNames, id: \.self) { name in
                    paymentLogo(name)
                }
            }
        }
    }

    private func paymentLogo(_ assetName: String) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(height: logoHeight(for: assetName))
            .frame(maxWidth: logoMaxWidth(for: assetName))
            .accessibilityHidden(true)
    }

    private func logoHeight(for assetName: String) -> CGFloat {
        switch assetName {
        case "payVisa", "payMastercard": 28
        case "payZelle": 26
        case "payVenmo": 16
        case "payPayPal": 20
        default: 22
        }
    }

    private func logoMaxWidth(for assetName: String) -> CGFloat {
        switch assetName {
        case "payVisa", "payMastercard": 48
        case "payZelle": 72
        case "payVenmo": 70
        case "payPayPal": 86
        default: 70
        }
    }

    private func accessibilityLabel(
        for method: PaymentMethodKind,
        isSelected: Bool,
        isDefault: Bool
    ) -> String {
        var parts = [method.title]
        if isDefault { parts.append("default") }
        if isSelected { parts.append("selected") }
        return parts.joined(separator: ", ")
    }

    private var poweredByFooter: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Powered by")
                    .font(.footnote)
                    .foregroundStyle(linkGray)
                Text("Stripe")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.darkText)
            }
            Spacer()
            HStack(spacing: 16) {
                Button("Terms") {}
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(linkGray)
                Button("Privacy") {}
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(linkGray)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Transactions

    private var transactionsList: some View {
        VStack(spacing: 14) {
            ForEach(transactions) { transaction in
                transactionCard(transaction)
            }
        }
    }

    private func transactionCard(_ transaction: PaymentTransaction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.providerName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(rowTitle)
                    Text(transaction.location)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(mutedLabel)
                }
                Spacer(minLength: 8)
                Text(transaction.type.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(transaction.type == .typeA ? typeABadge : typeBBadge)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Rectangle()
                .fill(Color(red: 0.937, green: 0.937, blue: 0.937))
                .frame(height: 1)

            detailRow(label: "Date", value: transaction.dateLabel)
            HStack {
                Text("Price")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(mutedLabel)
                Spacer()
                HStack(spacing: 16) {
                    Text(transaction.hourlyPriceLabel)
                    Text(transaction.durationLabel)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(rowTitle)
            }
            detailRow(label: "Amount", value: transaction.amountLabel, valueWeight: .bold, valueColor: Theme.darkText)
        }
        .padding(16)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func detailRow(
        label: String,
        value: String,
        valueWeight: Font.Weight = .semibold,
        valueColor: Color? = nil
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(mutedLabel)
            Spacer()
            Text(value)
                .font(.subheadline.weight(valueWeight))
                .foregroundStyle(valueColor ?? rowTitle)
        }
    }
}

/// Scales the whole payment-method header (radio + title + logos) as one unit on press.
private struct PaymentMethodRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1, anchor: .leading)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    PaymentView()
}
