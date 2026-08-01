import SwiftUI

struct PaymentView: View {
    @State private var segment: PaymentSegment = .paymentMethod
    @State private var selectedMethod: PaymentMethodKind = .bankAccount
    @State private var bankDetails = BankAccountDetails.sample
    @State private var showSendGiftMenu = false
    @State private var showGiftInfo = false
    @State private var showBookingsInfo = false
    @State private var giftActionMessage: String?

    private let giftBalance = 240
    private let completedBookings = 5
    private let transactions = PaymentTransaction.samples

    private let summaryCardBG = Color(red: 0.988, green: 0.988, blue: 0.988) // #FCFCFC
    private let segmentTrack = Color(red: 0.941, green: 0.957, blue: 0.976) // #F0F4F9
    private let giftIconBG = Color(red: 0.941, green: 0.361, blue: 0.267) // #F05C44
    private let serviceIconBG = Color(red: 0.969, green: 0.698, blue: 0.420) // #F7B26B
    private let sendGiftTint = Color(red: 0.141, green: 0.420, blue: 0.992).opacity(0.08)
    private let sendGiftArrow = Color(red: 0.141, green: 0.420, blue: 0.992)
    private let selectedMethodFill = Color(red: 1.0, green: 0.847, blue: 0.796) // #FFD8CB
    private let selectedMethodStroke = Color(red: 0.941, green: 0.361, blue: 0.267)
    private let typeABadge = Color(red: 0.710, green: 0.894, blue: 0.792) // #B5E4CA
    private let typeBBadge = Color(red: 1.0, green: 0.737, blue: 0.600) // #FFBC99
    private let mutedLabel = Color(red: 0.435, green: 0.463, blue: 0.494) // #6F767E
    private let rowTitle = Color(red: 0.200, green: 0.220, blue: 0.247) // #33383F
    private let cardFill = Color(red: 0.957, green: 0.957, blue: 0.957).opacity(0.5)
    private let brandBlue = Color(red: 0.141, green: 0.420, blue: 0.992)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    segmentControl
                    Group {
                        switch segment {
                        case .paymentMethod:
                            paymentMethodsCard
                        case .transactions:
                            transactionsList
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .topTrailing) {
                if showSendGiftMenu {
                    sendGiftMenu
                        .padding(.trailing, 28)
                        .padding(.top, 150)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
                        .zIndex(2)
                }
            }
            .onTapGesture {
                if showSendGiftMenu {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSendGiftMenu = false
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
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.darkText)
                }

                Spacer(minLength: 8)

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
            }

            Rectangle()
                .fill(Color(red: 0.937, green: 0.937, blue: 0.937))
                .frame(height: 1)

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
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.darkText)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(summaryCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 2)
    }

    private var sendGiftMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SendGiftAction.allCases) { action in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSendGiftMenu = false
                    }
                    giftActionMessage = "\(action.rawValue) flow coming soon."
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: action.systemImage)
                            .font(.body)
                            .foregroundStyle(Theme.darkText)
                            .frame(width: 22)
                        Text(action.rawValue)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.darkText)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if action != SendGiftAction.allCases.last {
                    Divider().padding(.leading, 50)
                }
            }
        }
        .frame(width: 200)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
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

    private var paymentMethodsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.darkText)

            VStack(spacing: 12) {
                ForEach(PaymentMethodKind.allCases) { method in
                    paymentMethodRow(method)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    @ViewBuilder
    private func paymentMethodRow(_ method: PaymentMethodKind) -> some View {
        let isSelected = selectedMethod == method

        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMethod = method
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? selectedMethodStroke : mutedLabel)

                    Text(method.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    trailingAccessory(for: method)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected, method == .bankAccount {
                bankAccountFields
            }
        }
        .padding(14)
        .background(isSelected && method == .bankAccount ? selectedMethodFill : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected && method == .bankAccount ? selectedMethodStroke : Color.clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func trailingAccessory(for method: PaymentMethodKind) -> some View {
        switch method {
        case .bankAccount:
            EmptyView()
        case .zelle:
            brandPill("Zelle", fill: Color(red: 0.42, green: 0.20, blue: 0.70), text: .white)
        case .venmo:
            brandPill("Venmo", fill: Color(red: 0.20, green: 0.55, blue: 0.86), text: .white)
        case .paypal:
            brandPill("PayPal", fill: Color(red: 0.05, green: 0.20, blue: 0.55), text: .white)
        case .giftFund:
            Text("$\(giftBalance)")
                .font(.body.weight(.semibold))
                .foregroundStyle(brandBlue)
        case .creditCard:
            HStack(spacing: 6) {
                brandPill("VISA", fill: Color(red: 0.10, green: 0.25, blue: 0.60), text: .white)
                brandPill("MC", fill: Color(red: 0.85, green: 0.25, blue: 0.20), text: .white)
            }
        }
    }

    private func brandPill(_ title: String, fill: Color, text: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var bankAccountFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            paymentTextField(title: "Account Holder Name", text: $bankDetails.accountHolderName)
            paymentTextField(title: "Account Number", text: $bankDetails.accountNumber)
            paymentTextField(title: "ABA Routing Number", text: $bankDetails.abaRoutingNumber)
        }
    }

    private func paymentTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(mutedLabel)
            TextField(title, text: text)
                .font(.body)
                .foregroundStyle(Theme.darkText)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
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

#Preview {
    PaymentView()
}
