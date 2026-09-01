package com.embelife.app.model

import java.time.LocalDate

enum class GiftExperienceRoute {
    Confirm,
    PaymentMethod,
    Sent,
    SignUp,
    Received,
}

/** Draft state for the Gift $ Amount flow. */
class GiftDraft {
    var amountInput: String = "1000"
    var selectedMethod: PaymentMethodKind = PaymentMethodKind.CreditCard
    var bankDetails: BankAccountDetails = BankAccountDetails.sample
    var zelleDetails: ContactPaymentDetails = ContactPaymentDetails.zelleSample
    var venmoDetails: ContactPaymentDetails = ContactPaymentDetails.venmoSample
    var paypalDetails: ContactPaymentDetails = ContactPaymentDetails.paypalSample
    var creditCardDetails: CreditCardDetails = CreditCardDetails.sample
    var recipientLabel: String = "Gift money to EmBeLife User"
    var senderDisplayName: String = "J. R"
    var receivedDate: LocalDate = LocalDate.of(2026, 5, 27)

    var amount: Double
        get() = amountInput.filter { it.isDigit() || it == '.' }.toDoubleOrNull() ?: 0.0
        set(value) {
            val clamped = value.coerceAtLeast(0.0)
            amountInput = if (clamped == kotlin.math.floor(clamped)) {
                clamped.toInt().toString()
            } else {
                "%.2f".format(clamped)
            }
        }

    val isValidGiftAmount: Boolean get() = amount > 0
    val amountLabel: String get() = formatCurrency(amount)

    fun applyPreset(preset: Double) {
        amount = preset
    }

    fun sanitizeAmountInput(raw: String) {
        amountInput = raw.filter { it.isDigit() }.take(7)
    }

    val paymentMethodSummaryTitle: String
        get() = when (selectedMethod) {
            PaymentMethodKind.BankAccount -> "Bank · ${last4(bankDetails.accountNumber)}"
            PaymentMethodKind.Zelle -> "Zelle"
            PaymentMethodKind.Venmo -> "Venmo"
            PaymentMethodKind.Paypal -> "PayPal"
            PaymentMethodKind.CreditCard -> "${cardBrandLabel(creditCardDetails.cardNumber)} · ${last4(creditCardDetails.cardNumber)}"
            PaymentMethodKind.GiftFund -> "Gift Fund"
        }

    val paymentMethodSummarySubtitle: String
        get() = when (selectedMethod) {
            PaymentMethodKind.CreditCard -> "Expires ${creditCardDetails.expiry}"
            PaymentMethodKind.BankAccount -> "ACH · 1 – 3 Business days"
            PaymentMethodKind.Zelle, PaymentMethodKind.Venmo, PaymentMethodKind.Paypal -> "Instant · Free"
            PaymentMethodKind.GiftFund -> "Gift balance"
        }

    val paymentDeliveryLabel: String
        get() = when (selectedMethod) {
            PaymentMethodKind.BankAccount -> "1 – 3 Business days"
            else -> "Instant"
        }

    companion object {
        val amountPresets = listOf(50.0, 100.0, 200.0, 500.0, 1_000.0, 2_000.0)
        val giftPaymentMethods = listOf(
            PaymentMethodKind.BankAccount,
            PaymentMethodKind.Zelle,
            PaymentMethodKind.Venmo,
            PaymentMethodKind.Paypal,
            PaymentMethodKind.CreditCard,
        )

        fun formatCurrency(value: Double): String = "$${value.toInt()}"

        private fun last4(digits: String): String {
            val cleaned = digits.filter { it.isDigit() }
            return when {
                cleaned.length >= 4 -> cleaned.takeLast(4)
                cleaned.isEmpty() -> "----"
                else -> cleaned
            }
        }

        private fun cardBrandLabel(number: String): String {
            val cleaned = number.filter { it.isDigit() }
            return when {
                cleaned.startsWith("4") -> "Visa"
                cleaned.startsWith("5") -> "Mastercard"
                else -> "Card"
            }
        }
    }
}

enum class SendGiftAction(val title: String) {
    GiftAmount("Gift $ Amount"),
    GiftService("Gift Service"),
    ReceiveGift("Receive Gift"),
}

enum class NotesScreenPhase { Welcome, Ready, Conversation }

enum class VoiceConversationPhase { Listening, UserTranscript, Playback, AiReply }

data class VoiceNoteMessage(
    val id: String,
    val role: Role,
    val text: String,
    val timeLabel: String,
    val showsWaveform: Boolean = false,
) {
    enum class Role { User, Assistant }
}

object VoiceNoteSample {
    const val userTranscript = "hi, im looking for child care for my kid..."
    const val assistantReply = "I got it, let me look for some options for you"
    const val userTime = "08:33"
    const val audioDuration = "0:08"
}
