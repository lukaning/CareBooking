import Foundation

enum PaymentSegment: String, CaseIterable, Identifiable {
    case paymentMethod = "Payment method"
    case transactions = "Transactions"

    var id: String { rawValue }
}

enum PaymentMethodKind: String, CaseIterable, Identifiable, Hashable {
    case bankAccount
    case zelle
    case venmo
    case paypal
    case giftFund
    case creditCard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bankAccount: "Pay by Bank Account"
        case .zelle: "Pay by Zelle"
        case .venmo: "Pay by Venmo"
        case .paypal: "Pay by PayPal"
        case .giftFund: "Pay by Gift Fund"
        case .creditCard: "Pay by Credit Card"
        }
    }
}

enum SendGiftAction: String, CaseIterable, Identifiable {
    case giftAmount = "Gift $ Amount"
    case giftService = "Gift Service"
    case receiveGift = "Receive Gift"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .giftAmount: "gift"
        case .giftService, .receiveGift: "hand.raised"
        }
    }
}

enum PaymentTransactionType: String, Hashable {
    case typeA = "Type A"
    case typeB = "Type B"

    var badgeFill: String {
        switch self {
        case .typeA: "TypeABadge"
        case .typeB: "TypeBBadge"
        }
    }
}

struct PaymentTransaction: Identifiable, Hashable {
    var id: String
    var providerName: String
    var location: String
    var dateLabel: String
    var hourlyPriceLabel: String
    var durationLabel: String
    var amountLabel: String
    var type: PaymentTransactionType

    static let samples: [PaymentTransaction] = [
        PaymentTransaction(
            id: "tx-1",
            providerName: "Marvin McKinney",
            location: "Service at 1st street, San Francisco",
            dateLabel: "14 May 2025",
            hourlyPriceLabel: "$25",
            durationLabel: "3 hours",
            amountLabel: "$75",
            type: .typeA
        ),
        PaymentTransaction(
            id: "tx-2",
            providerName: "Marvin McKinney",
            location: "Service at 1st street, San Francisco",
            dateLabel: "7 May 2025",
            hourlyPriceLabel: "$25",
            durationLabel: "3 hours",
            amountLabel: "$75",
            type: .typeA
        ),
        PaymentTransaction(
            id: "tx-3",
            providerName: "Christian Dawson",
            location: "Service at 2nd street, San Francisco",
            dateLabel: "26 April 2025",
            hourlyPriceLabel: "$25",
            durationLabel: "3 hours",
            amountLabel: "$75",
            type: .typeB
        )
    ]
}

struct BankAccountDetails: Hashable {
    var accountHolderName: String
    var accountNumber: String
    var abaRoutingNumber: String

    static let sample = BankAccountDetails(
        accountHolderName: "Robbi Darwis",
        accountNumber: "8888 - 8888 - 8888 - 8888",
        abaRoutingNumber: "8888999"
    )
}
