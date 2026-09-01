package com.embelife.app.ui.payment

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.model.BankAccountDetails
import com.embelife.app.model.ContactPaymentDetails
import com.embelife.app.model.CreditCardDetails
import com.embelife.app.model.GiftDraft
import com.embelife.app.model.GiftExperienceRoute
import com.embelife.app.model.PaymentMethodKind
import com.embelife.app.model.PaymentSegment
import com.embelife.app.model.PaymentTransaction
import com.embelife.app.model.PaymentTransactionType
import com.embelife.app.model.SendGiftAction
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.gift.GiftExperienceHost
import com.embelife.app.ui.theme.EmBeColors

private val SoftBorder = Color(0xFFE6E8EE)
private val SelectedFill = Color(0xFFFFD8CB)
private val SegmentTrack = Color(0xFFF0F4F9)
private val GiftIconBG = Color(0xFFF05C44)
private val SendGiftBlue = Color(0xFF246BF7)
private val TypeABadge = Color(0xFFB5E4CA)
private val TypeBBadge = Color(0xFFFFBC99)
private val RadioRing = Color(0xFFB2B8C2)

@Composable
fun PaymentScreen(contentPadding: PaddingValues) {
    var segment by remember { mutableStateOf(PaymentSegment.PaymentMethod) }
    var selectedMethod by remember { mutableStateOf<PaymentMethodKind?>(PaymentMethodKind.defaultMethod) }
    var bankDetails by remember { mutableStateOf(BankAccountDetails.sample) }
    var zelleDetails by remember { mutableStateOf(ContactPaymentDetails.zelleSample) }
    var venmoDetails by remember { mutableStateOf(ContactPaymentDetails.venmoSample) }
    var paypalDetails by remember { mutableStateOf(ContactPaymentDetails.paypalSample) }
    var creditCardDetails by remember { mutableStateOf(CreditCardDetails.sample) }
    var showSendGiftMenu by remember { mutableStateOf(false) }
    var giftRoute by remember { mutableStateOf<GiftExperienceRoute?>(null) }
    var giftDraft by remember { mutableStateOf(GiftDraft()) }
    var alertMessage by remember { mutableStateOf<String?>(null) }
    var confirmMessage by remember { mutableStateOf<String?>(null) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(bottom = contentPadding.calculateBottomPadding()),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("Payment", color = EmBeColors.DarkText, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                SummaryCard(
                    showMenu = showSendGiftMenu,
                    onToggleMenu = { showSendGiftMenu = !showSendGiftMenu },
                    onGiftAction = { action ->
                        showSendGiftMenu = false
                        when (action) {
                            SendGiftAction.GiftAmount -> {
                                giftDraft = GiftDraft()
                                giftRoute = GiftExperienceRoute.Confirm
                            }
                            SendGiftAction.ReceiveGift -> {
                                giftDraft = GiftDraft()
                                giftRoute = GiftExperienceRoute.Received
                            }
                            SendGiftAction.GiftService -> {
                                alertMessage = "Gift a service is coming soon."
                            }
                        }
                    },
                    onGiftInfo = { alertMessage = "Gift Fund balance available for booking payments." },
                    onBookingsInfo = { alertMessage = "Completed bookings linked to your gift activity." },
                )

                SegmentControl(selected = segment, onSelect = { segment = it })

                when (segment) {
                    PaymentSegment.PaymentMethod -> {
                        PaymentMethodKind.entries.forEach { method ->
                            MethodCard(
                                method = method,
                                selected = selectedMethod == method,
                                bankDetails = bankDetails,
                                zelleDetails = zelleDetails,
                                venmoDetails = venmoDetails,
                                paypalDetails = paypalDetails,
                                creditCardDetails = creditCardDetails,
                                onSelect = { selectedMethod = method },
                                onBankChange = { bankDetails = it },
                                onZelleChange = { zelleDetails = it },
                                onVenmoChange = { venmoDetails = it },
                                onPaypalChange = { paypalDetails = it },
                                onCardChange = { creditCardDetails = it },
                                onConfirm = {
                                    confirmMessage = "${method.title} saved as your payment method."
                                },
                            )
                        }
                    }
                    PaymentSegment.Transactions -> {
                        PaymentTransaction.samples.forEach { tx ->
                            TransactionCard(tx)
                        }
                    }
                }
            }
        }

        if (showSendGiftMenu) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable { showSendGiftMenu = false },
            )
        }
    }

    giftRoute?.let { route ->
        GiftExperienceHost(
            initialRoute = route,
            draft = giftDraft,
            onDismiss = { giftRoute = null },
        )
    }

    alertMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = { alertMessage = null },
            confirmButton = { TextButton(onClick = { alertMessage = null }) { Text("OK") } },
            title = { Text("EmBeLife") },
            text = { Text(msg) },
        )
    }
    confirmMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = { confirmMessage = null },
            confirmButton = { TextButton(onClick = { confirmMessage = null }) { Text("OK") } },
            title = { Text("Confirmed") },
            text = { Text(msg) },
        )
    }
}

@Composable
private fun SummaryCard(
    showMenu: Boolean,
    onToggleMenu: () -> Unit,
    onGiftAction: (SendGiftAction) -> Unit,
    onGiftInfo: () -> Unit,
    onBookingsInfo: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Color(0xFFFCFCFC))
            .border(1.dp, SoftBorder, RoundedCornerShape(20.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SummaryTile(
                iconBG = GiftIconBG,
                icon = { Icon(Icons.Filled.CardGiftcard, null, tint = Color.White, modifier = Modifier.size(20.dp)) },
                label = "Gift Balance",
                value = "$240",
                onInfo = onGiftInfo,
                modifier = Modifier.weight(1f),
            )
            SummaryTile(
                iconBG = Color(0xFFF7B26B),
                icon = { Icon(Icons.Filled.Work, null, tint = Color.White, modifier = Modifier.size(20.dp)) },
                label = "Bookings",
                value = "5",
                onInfo = onBookingsInfo,
                modifier = Modifier.weight(1f),
            )
        }

        Box {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(SendGiftBlue.copy(alpha = 0.08f))
                    .clickable(onClick = onToggleMenu)
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Send Gift", color = SendGiftBlue, fontWeight = FontWeight.Bold, fontSize = 16.sp, modifier = Modifier.weight(1f))
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = SendGiftBlue)
            }
            if (showMenu) {
                Column(
                    modifier = Modifier
                        .padding(top = 56.dp)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color.White)
                        .border(1.dp, SoftBorder, RoundedCornerShape(14.dp)),
                ) {
                    SendGiftAction.entries.forEach { action ->
                        Text(
                            action.title,
                            color = EmBeColors.DarkText,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onGiftAction(action) }
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryTile(
    iconBG: Color,
    icon: @Composable () -> Unit,
    label: String,
    value: String,
    onInfo: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Color(0xFFF0F1F5))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(32.dp).clip(CircleShape).background(iconBG), contentAlignment = Alignment.Center) { icon() }
            Spacer(Modifier.weight(1f))
            Icon(Icons.Filled.Info, null, tint = EmBeColors.MutedText, modifier = Modifier.size(16.dp).clickable(onClick = onInfo))
        }
        Text(label, color = EmBeColors.MutedText, fontSize = 12.sp)
        Text(value, color = EmBeColors.DarkText, fontSize = 22.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun SegmentControl(selected: PaymentSegment, onSelect: (PaymentSegment) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(SegmentTrack)
            .padding(4.dp),
    ) {
        PaymentSegment.entries.forEach { segment ->
            val isSelected = selected == segment
            Text(
                segment.title,
                color = if (isSelected) EmBeColors.DarkText else EmBeColors.MutedText,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (isSelected) Color.White else Color.Transparent)
                    .clickable { onSelect(segment) }
                    .padding(vertical = 11.dp),
            )
        }
    }
}

@Composable
private fun MethodCard(
    method: PaymentMethodKind,
    selected: Boolean,
    bankDetails: BankAccountDetails,
    zelleDetails: ContactPaymentDetails,
    venmoDetails: ContactPaymentDetails,
    paypalDetails: ContactPaymentDetails,
    creditCardDetails: CreditCardDetails,
    onSelect: () -> Unit,
    onBankChange: (BankAccountDetails) -> Unit,
    onZelleChange: (ContactPaymentDetails) -> Unit,
    onVenmoChange: (ContactPaymentDetails) -> Unit,
    onPaypalChange: (ContactPaymentDetails) -> Unit,
    onCardChange: (CreditCardDetails) -> Unit,
    onConfirm: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(if (selected) SelectedFill else Color.White)
            .border(if (selected) 1.5.dp else 1.dp, if (selected) EmBeColors.BrandOrange else SoftBorder, RoundedCornerShape(14.dp))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().clickable(onClick = onSelect),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(
                modifier = Modifier.size(22.dp).border(1.5.dp, if (selected) EmBeColors.BrandOrange else RadioRing, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                if (selected) Box(Modifier.size(12.dp).clip(CircleShape).background(EmBeColors.BrandOrange))
            }
            Text(method.title, color = if (selected) EmBeColors.LinkBlue else EmBeColors.DarkText, modifier = Modifier.weight(1f), fontWeight = FontWeight.Medium)
            when (method) {
                PaymentMethodKind.GiftFund -> Text("$240", color = EmBeColors.LinkBlue, fontWeight = FontWeight.SemiBold)
                else -> Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    method.logoResIds.forEach { res ->
                        Image(painterResource(res), null, contentScale = ContentScale.Fit, modifier = Modifier.height(if (res == R.drawable.pay_visa) 14.dp else 18.dp))
                    }
                }
            }
        }
        if (selected) {
            when (method) {
                PaymentMethodKind.BankAccount -> {
                    PayField("Account Holder Name", bankDetails.accountHolderName) { onBankChange(bankDetails.copy(accountHolderName = it)) }
                    PayField("Account Number", bankDetails.accountNumber) { onBankChange(bankDetails.copy(accountNumber = it)) }
                    PayField("ABA Routing Number", bankDetails.abaRoutingNumber) { onBankChange(bankDetails.copy(abaRoutingNumber = it)) }
                }
                PaymentMethodKind.Zelle -> PayField("Email or Mobile phone number", zelleDetails.contact) { onZelleChange(zelleDetails.copy(contact = it)) }
                PaymentMethodKind.Venmo -> PayField("Venmo username or phone", venmoDetails.contact) { onVenmoChange(venmoDetails.copy(contact = it)) }
                PaymentMethodKind.Paypal -> PayField("PayPal email", paypalDetails.contact) { onPaypalChange(paypalDetails.copy(contact = it)) }
                PaymentMethodKind.GiftFund -> {
                    Text("$240", fontSize = 32.sp, fontWeight = FontWeight.Bold, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                    Text("Available gift fund balance", color = EmBeColors.MutedText, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                }
                PaymentMethodKind.CreditCard -> {
                    PayField("Cardholder Name", creditCardDetails.cardholderName) { onCardChange(creditCardDetails.copy(cardholderName = it)) }
                    PayField("Card Number", creditCardDetails.cardNumber) { onCardChange(creditCardDetails.copy(cardNumber = it)) }
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Box(Modifier.weight(1f)) { PayField("Expiry", creditCardDetails.expiry) { onCardChange(creditCardDetails.copy(expiry = it)) } }
                        Box(Modifier.weight(1f)) { PayField("CVC", creditCardDetails.cvc) { onCardChange(creditCardDetails.copy(cvc = it)) } }
                    }
                }
            }
            if (method != PaymentMethodKind.GiftFund) {
                PrimaryOrangeButton(text = "Confirm", onClick = onConfirm)
            }
        }
    }
}

@Composable
private fun PayField(title: String, value: String, onValueChange: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(title, color = Color(0xFF1A3373), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(10.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = SoftBorder,
                unfocusedBorderColor = SoftBorder,
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White,
            ),
        )
    }
}

@Composable
private fun TransactionCard(tx: PaymentTransaction) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Color(0xFFF4F4F4).copy(alpha = 0.5f))
            .border(1.dp, SoftBorder, RoundedCornerShape(14.dp))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(tx.providerName, fontWeight = FontWeight.Bold, color = EmBeColors.DarkText, modifier = Modifier.weight(1f))
            Text(
                tx.type.label,
                color = EmBeColors.DarkText,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(if (tx.type == PaymentTransactionType.TypeA) TypeABadge else TypeBBadge)
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            )
        }
        Text(tx.location, color = EmBeColors.MutedText, fontSize = 13.sp)
        Row {
            Text(tx.dateLabel, color = EmBeColors.MutedText, fontSize = 12.sp, modifier = Modifier.weight(1f))
            Text("${tx.hourlyPriceLabel} · ${tx.durationLabel}", color = EmBeColors.MutedText, fontSize = 12.sp)
        }
        Text(tx.amountLabel, color = EmBeColors.DarkText, fontWeight = FontWeight.Bold, fontSize = 18.sp)
    }
}
