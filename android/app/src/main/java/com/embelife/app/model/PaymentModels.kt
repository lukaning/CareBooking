package com.embelife.app.model

import com.embelife.app.R

/** Port of `PaymentMethodKind`. */
enum class PaymentMethodKind(val title: String) {
    BankAccount("Pay by Bank Account"),
    Zelle("Pay by Zelle"),
    Venmo("Pay by Venmo"),
    Paypal("Pay by PayPal"),
    GiftFund("Pay by Gift Fund"),
    CreditCard("Pay by Credit Card");

    val logoResIds: List<Int>
        get() = when (this) {
            BankAccount -> emptyList()
            Zelle -> listOf(R.drawable.pay_zelle)
            Venmo -> listOf(R.drawable.pay_venmo)
            Paypal -> listOf(R.drawable.pay_pay_pal)
            GiftFund -> emptyList()
            CreditCard -> listOf(R.drawable.pay_visa, R.drawable.pay_mastercard)
        }

    val summaryLabel: String
        get() = when (this) {
            BankAccount -> "Bank account"
            Zelle -> "Zelle"
            Venmo -> "Venmo"
            Paypal -> "PayPal"
            GiftFund -> "Gift Fund"
            CreditCard -> "Credit card"
        }

    companion object {
        val defaultMethod: PaymentMethodKind = BankAccount
    }
}

data class BankAccountDetails(
    var accountHolderName: String = "",
    var accountNumber: String = "",
    var abaRoutingNumber: String = "",
) {
    companion object {
        val sample = BankAccountDetails(
            accountHolderName = "Robbi Darwis",
            accountNumber = "8888 - 8888 - 8888 - 8888",
            abaRoutingNumber = "8888999",
        )
    }
}

data class ContactPaymentDetails(
    var contact: String = "",
) {
    companion object {
        val zelleSample = ContactPaymentDetails(contact = "4158888888")
        val venmoSample = ContactPaymentDetails(contact = "@robbidarwis")
        val paypalSample = ContactPaymentDetails(contact = "robbi@email.com")
    }
}

data class CreditCardDetails(
    var cardholderName: String = "",
    var cardNumber: String = "",
    var expiry: String = "",
    var cvc: String = "",
) {
    companion object {
        val sample = CreditCardDetails(
            cardholderName = "Robbi Darwis",
            cardNumber = "4242 4242 4242 4242",
            expiry = "12/28",
            cvc = "123",
        )
    }
}

enum class PaymentSegment(val title: String) {
    PaymentMethod("Payment method"),
    Transactions("Transactions"),
}

enum class PaymentTransactionType(val label: String) {
    TypeA("Type A"),
    TypeB("Type B"),
}

data class PaymentTransaction(
    val id: String,
    val providerName: String,
    val location: String,
    val dateLabel: String,
    val hourlyPriceLabel: String,
    val durationLabel: String,
    val amountLabel: String,
    val type: PaymentTransactionType,
) {
    companion object {
        val samples: List<PaymentTransaction> = listOf(
            PaymentTransaction(
                id = "tx-1",
                providerName = "Marvin McKinney",
                location = "Service at 1st street, San Francisco",
                dateLabel = "14 May 2025",
                hourlyPriceLabel = "$25",
                durationLabel = "3 hours",
                amountLabel = "$75",
                type = PaymentTransactionType.TypeA,
            ),
            PaymentTransaction(
                id = "tx-2",
                providerName = "Marvin McKinney",
                location = "Service at 1st street, San Francisco",
                dateLabel = "7 May 2025",
                hourlyPriceLabel = "$25",
                durationLabel = "3 hours",
                amountLabel = "$75",
                type = PaymentTransactionType.TypeA,
            ),
            PaymentTransaction(
                id = "tx-3",
                providerName = "Christian Dawson",
                location = "Service at 2nd street, San Francisco",
                dateLabel = "26 April 2025",
                hourlyPriceLabel = "$25",
                durationLabel = "3 hours",
                amountLabel = "$75",
                type = PaymentTransactionType.TypeB,
            ),
        )
    }
}
