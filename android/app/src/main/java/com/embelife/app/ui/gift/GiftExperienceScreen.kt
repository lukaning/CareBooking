package com.embelife.app.ui.gift

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
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
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.embelife.app.R
import com.embelife.app.model.GiftDraft
import com.embelife.app.model.GiftExperienceRoute
import com.embelife.app.model.PaymentMethodKind
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import java.time.format.DateTimeFormatter

private val Blush = Color(0xFFFFF5F2)
private val SelectedFill = Color(0xFFFFD8CB)
private val SoftBorder = Color(0xFFE6E8EE)

@Composable
fun GiftExperienceHost(
    initialRoute: GiftExperienceRoute,
    draft: GiftDraft = GiftDraft(),
    onDismiss: () -> Unit,
) {
    var route by remember { mutableStateOf(initialRoute) }
    var amountInput by remember { mutableStateOf(draft.amountInput) }
    var selectedMethod by remember { mutableStateOf(draft.selectedMethod) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(EmBeColors.BrandOrange)
                .statusBarsPadding(),
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Filled.Close,
                    contentDescription = "Close",
                    tint = Color.White,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.2f))
                        .clickable(onClick = onDismiss)
                        .padding(6.dp),
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    when (route) {
                        GiftExperienceRoute.Confirm -> "Send a Gift"
                        GiftExperienceRoute.PaymentMethod -> "Payment"
                        GiftExperienceRoute.Sent -> "Gift Sent"
                        GiftExperienceRoute.SignUp -> "Create Account"
                        GiftExperienceRoute.Received -> "Gift Received"
                    },
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                )
                Spacer(modifier = Modifier.weight(1f))
                Spacer(modifier = Modifier.size(36.dp))
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp))
                    .background(Blush)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                when (route) {
                    GiftExperienceRoute.Confirm -> ConfirmStep(
                        amountInput = amountInput,
                        onAmountChange = { amountInput = it.filter { c -> c.isDigit() }.take(7) },
                        recipient = draft.recipientLabel,
                        onContinue = {
                            draft.sanitizeAmountInput(amountInput)
                            if (draft.isValidGiftAmount) route = GiftExperienceRoute.PaymentMethod
                        },
                    )
                    GiftExperienceRoute.PaymentMethod -> PaymentStep(
                        selectedMethod = selectedMethod,
                        onSelect = { selectedMethod = it },
                        onContinue = {
                            draft.selectedMethod = selectedMethod
                            route = GiftExperienceRoute.Sent
                        },
                    )
                    GiftExperienceRoute.Sent -> SentStep(
                        amountLabel = GiftDraft.formatCurrency(amountInput.filter { it.isDigit() }.toDoubleOrNull() ?: 0.0),
                        methodTitle = selectedMethod.summaryLabel,
                        onContinue = { route = GiftExperienceRoute.SignUp },
                        onDone = onDismiss,
                    )
                    GiftExperienceRoute.SignUp -> SignUpStep(onDone = onDismiss)
                    GiftExperienceRoute.Received -> ReceivedStep(
                        amountLabel = draft.amountLabel,
                        sender = draft.senderDisplayName,
                        dateLabel = draft.receivedDate.format(DateTimeFormatter.ofPattern("MMMM d, yyyy")),
                        onClaim = { route = GiftExperienceRoute.SignUp },
                        onDone = onDismiss,
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ConfirmStep(
    amountInput: String,
    onAmountChange: (String) -> Unit,
    recipient: String,
    onContinue: () -> Unit,
) {
    Text(recipient, color = EmBeColors.DarkText, fontSize = 20.sp, fontWeight = FontWeight.Bold)
    Text("Choose an amount", color = EmBeColors.MutedText, fontSize = 14.sp)
    OutlinedTextField(
        value = amountInput,
        onValueChange = onAmountChange,
        prefix = { Text("$") },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
        shape = RoundedCornerShape(12.dp),
    )
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        GiftDraft.amountPresets.forEach { preset ->
            val label = GiftDraft.formatCurrency(preset)
            val selected = amountInput == preset.toInt().toString()
            Text(
                label,
                color = if (selected) Color.White else EmBeColors.DarkText,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (selected) EmBeColors.BrandOrange else Color.White)
                    .border(1.dp, if (selected) EmBeColors.BrandOrange else SoftBorder, RoundedCornerShape(10.dp))
                    .clickable { onAmountChange(preset.toInt().toString()) }
                    .padding(horizontal = 14.dp, vertical = 10.dp),
            )
        }
    }
    Spacer(modifier = Modifier.height(8.dp))
    PrimaryOrangeButton(text = "Continue", enabled = amountInput.isNotEmpty(), onClick = onContinue)
}

@Composable
private fun PaymentStep(
    selectedMethod: PaymentMethodKind,
    onSelect: (PaymentMethodKind) -> Unit,
    onContinue: () -> Unit,
) {
    Text("How will you fund this gift?", color = EmBeColors.DarkText, fontSize = 18.sp, fontWeight = FontWeight.Bold)
    GiftDraft.giftPaymentMethods.forEach { method ->
        val selected = selectedMethod == method
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(if (selected) SelectedFill else Color.White)
                .border(1.dp, if (selected) EmBeColors.BrandOrange else SoftBorder, RoundedCornerShape(14.dp))
                .clickable { onSelect(method) }
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(22.dp)
                    .border(1.5.dp, if (selected) EmBeColors.BrandOrange else SoftBorder, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                if (selected) Box(Modifier.size(12.dp).clip(CircleShape).background(EmBeColors.BrandOrange))
            }
            Text(method.title, color = EmBeColors.DarkText, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
            method.logoResIds.take(1).forEach {
                Image(painterResource(it), null, contentScale = ContentScale.Fit, modifier = Modifier.height(18.dp))
            }
        }
    }
    PrimaryOrangeButton(text = "Send Gift", onClick = onContinue)
}

@Composable
private fun SentStep(amountLabel: String, methodTitle: String, onContinue: () -> Unit, onDone: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Image(painterResource(R.drawable.gift_celebration), null, modifier = Modifier.size(140.dp), contentScale = ContentScale.Fit)
        Text("Gift Sent!", color = EmBeColors.DarkText, fontSize = 24.sp, fontWeight = FontWeight.Bold)
        Text("$amountLabel via $methodTitle", color = EmBeColors.MutedText, textAlign = TextAlign.Center)
        PrimaryOrangeButton(text = "Create account to track gifts", onClick = onContinue)
        Text("Done", color = EmBeColors.LinkBlue, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable(onClick = onDone).padding(8.dp))
    }
}

@Composable
private fun ReceivedStep(amountLabel: String, sender: String, dateLabel: String, onClaim: () -> Unit, onDone: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Image(painterResource(R.drawable.receive_gift), null, modifier = Modifier.size(120.dp), contentScale = ContentScale.Fit)
        Text("You received $amountLabel", color = EmBeColors.DarkText, fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        Text("From $sender · $dateLabel", color = EmBeColors.MutedText, textAlign = TextAlign.Center)
        PrimaryOrangeButton(text = "Claim gift", onClick = onClaim)
        Text("Maybe later", color = EmBeColors.MutedText, modifier = Modifier.clickable(onClick = onDone).padding(8.dp))
    }
}

@Composable
private fun SignUpStep(onDone: () -> Unit) {
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    Text("Create your EmBeLife account", color = EmBeColors.DarkText, fontSize = 20.sp, fontWeight = FontWeight.Bold)
    OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
    OutlinedTextField(value = email, onValueChange = { email = it }, label = { Text("Email") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
    OutlinedTextField(value = password, onValueChange = { password = it }, label = { Text("Password") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
    PrimaryOrangeButton(text = "Sign Up", enabled = name.isNotBlank() && email.isNotBlank() && password.length >= 6, onClick = onDone)
}

@Composable
fun PayReceiveScreen(onDismiss: () -> Unit) {
    var tab by remember { mutableStateOf(0) }
    var giftRoute by remember { mutableStateOf<GiftExperienceRoute?>(null) }
    val link = "https://embelife.app/gift/katie"

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .statusBarsPadding()
                .padding(16.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Close, contentDescription = "Close", modifier = Modifier.clickable(onClick = onDismiss).size(28.dp))
                Spacer(modifier = Modifier.weight(1f))
                Text("Pay / Receive", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Spacer(modifier = Modifier.weight(1f))
                Spacer(modifier = Modifier.size(28.dp))
            }
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFFF0F1F4))
                    .padding(4.dp),
            ) {
                listOf("Scan code", "Gift me").forEachIndexed { index, title ->
                    Text(
                        title,
                        textAlign = TextAlign.Center,
                        fontWeight = if (tab == index) FontWeight.SemiBold else FontWeight.Normal,
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (tab == index) Color.White else Color.Transparent)
                            .clickable { tab = index }
                            .padding(vertical = 11.dp),
                    )
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
            if (tab == 0) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Box(
                        modifier = Modifier
                            .size(220.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color(0xFFF5F5F7))
                            .border(1.dp, SoftBorder, RoundedCornerShape(16.dp)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("QR Scanner\nplaceholder", textAlign = TextAlign.Center, color = EmBeColors.MutedText)
                    }
                    PrimaryOrangeButton(text = "Simulate scan", onClick = { giftRoute = GiftExperienceRoute.Received })
                }
            } else {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Image(painterResource(R.drawable.gift_me_illustration), null, modifier = Modifier.size(160.dp), contentScale = ContentScale.Fit)
                    Box(
                        modifier = Modifier
                            .size(160.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFFF5F5F7))
                            .border(1.dp, SoftBorder, RoundedCornerShape(12.dp)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("Your Gift QR", color = EmBeColors.MutedText)
                    }
                    Text(link, color = Color(0xFF7359D9), fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                }
            }
        }
    }

    giftRoute?.let {
        GiftExperienceHost(initialRoute = it, onDismiss = { giftRoute = null })
    }
}
