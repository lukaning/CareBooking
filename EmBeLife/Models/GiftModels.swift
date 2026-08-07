import Foundation

/// Navigation steps for gift giver (1–4) and receiver (5) experiences.
enum GiftExperienceRoute: Hashable {
    case confirm
    case paymentMethod
    case sent
    case signUp
    case received
}

/// Draft state for the Gift $ Amount flow.
@Observable
final class GiftDraft {
    /// Preset gift amounts user can pick without typing.
    static let amountPresets: [Double] = [50, 100, 200, 500, 1_000, 2_000]

    /// Backing typed amount for the number pad field (digits only).
    var amountInput: String = "1000"
    var selectedMethod: PaymentMethodKind = .creditCard
    var bankDetails = BankAccountDetails.sample
    var zelleDetails = ContactPaymentDetails.zelleSample
    var venmoDetails = ContactPaymentDetails.venmoSample
    var paypalDetails = ContactPaymentDetails.paypalSample
    var creditCardDetails = CreditCardDetails.sample

    /// Display recipient for giver confirm screen.
    var recipientLabel = "Gift money to EmBeLife User"
    /// Sample receiver attribution for experience_5.
    var senderDisplayName = "J. R"
    var receivedDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 27))
        ?? Date()

    /// Payment methods available when funding a gift (excludes Gift Fund).
    static let giftPaymentMethods: [PaymentMethodKind] = [
        .bankAccount, .zelle, .venmo, .paypal, .creditCard
    ]

    var amount: Double {
        get {
            let cleaned = amountInput.filter { $0.isNumber || $0 == "." }
            return Double(cleaned) ?? 0
        }
        set {
            let value = max(0, newValue)
            if value == floor(value) {
                amountInput = String(Int(value))
            } else {
                amountInput = String(format: "%.2f", value)
            }
        }
    }

    var isValidGiftAmount: Bool {
        amount > 0
    }

    var amountLabel: String {
        Self.formatCurrency(amount)
    }

    func applyPreset(_ preset: Double) {
        amount = preset
    }

    func sanitizeAmountInput(_ raw: String) {
        // Keep digits only for whole-dollar gifts via number pad.
        let digits = raw.filter(\.isNumber)
        // Cap length to avoid absurd values.
        amountInput = String(digits.prefix(7))
    }


    var paymentMethodSummaryTitle: String {
        switch selectedMethod {
        case .bankAccount:
            return "Bank · \(last4(bankDetails.accountNumber))"
        case .zelle:
            return "Zelle"
        case .venmo:
            return "Venmo"
        case .paypal:
            return "PayPal"
        case .creditCard:
            let brand = Self.cardBrandLabel(for: creditCardDetails.cardNumber)
            return "\(brand) · \(last4(creditCardDetails.cardNumber))"
        case .giftFund:
            return "Gift Fund"
        }
    }

    var paymentMethodSummarySubtitle: String {
        switch selectedMethod {
        case .creditCard:
            return "Expires \(creditCardDetails.expiry)"
        case .bankAccount:
            return "ACH · 1 – 3 Business days"
        case .zelle, .venmo, .paypal:
            return "Instant · Free"
        case .giftFund:
            return "Gift balance"
        }
    }

    var paymentDeliveryLabel: String {
        switch selectedMethod {
        case .bankAccount: "1 – 3 Business days"
        case .zelle, .venmo, .paypal, .creditCard, .giftFund: "Instant"
        }
    }

    var paymentFeeLabel: String { "Free" }

    var primaryLogoAsset: String? {
        switch selectedMethod {
        case .zelle: "payZelle"
        case .venmo: "payVenmo"
        case .paypal: "payPayPal"
        case .creditCard: "payVisa"
        default: nil
        }
    }

    var receivedDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: receivedDate)
    }

    static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func last4(_ digits: String) -> String {
        let cleaned = digits.filter(\.isNumber)
        guard cleaned.count >= 4 else { return cleaned.isEmpty ? "----" : cleaned }
        return String(cleaned.suffix(4))
    }

    private static func cardBrandLabel(for number: String) -> String {
        let cleaned = number.filter(\.isNumber)
        if cleaned.hasPrefix("4") { return "Visa" }
        if cleaned.hasPrefix("5") { return "Mastercard" }
        return "Card"
    }
}
