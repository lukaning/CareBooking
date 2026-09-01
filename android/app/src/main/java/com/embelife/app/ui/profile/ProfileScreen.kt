package com.embelife.app.ui.profile

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Verified
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
import com.embelife.app.R
import com.embelife.app.model.BookingStatus
import com.embelife.app.model.BookingTab
import com.embelife.app.model.FamilyMember
import com.embelife.app.model.MemberAvatarStyle
import com.embelife.app.model.Provider
import com.embelife.app.model.UserProfile
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.gift.PayReceiveScreen
import com.embelife.app.ui.review.RateAndReviewScreen
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import java.util.UUID

private val SoftBorder = Color(0xFFE6E8EE)
private val RequiredPink = Color(0xFFFF4A9E)
private val GiftPurple = Color(0xFF9E85E0)

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ProfileScreen(
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    var showEdit by remember { mutableStateOf(false) }
    var showPayReceive by remember { mutableStateOf(false) }
    var reviewProvider by remember { mutableStateOf<Provider?>(null) }
    var bookingTab by remember { mutableStateOf(BookingTab.Booked) }
    val profile = appViewModel.profile

    Box(modifier = Modifier.fillMaxSize().background(Color.White)) {
        Column(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = "Back",
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFE8E9ED))
                        .clickable(onClick = onDismiss)
                        .padding(4.dp),
                )
                Spacer(modifier = Modifier.weight(1f))
                Text("Profile", fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    Icons.Filled.Edit,
                    contentDescription = "Edit",
                    tint = EmBeColors.LinkBlue,
                    modifier = Modifier.size(28.dp).clickable { showEdit = true },
                )
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                if (!profile.isFilled) {
                    EmptyProfileCard(onEdit = { showEdit = true })
                } else {
                    FilledProfileHeader(profile)
                }

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    ActionChip("Pay / Receive", GiftPurple, Modifier.weight(1f)) { showPayReceive = true }
                    ActionChip("Edit Profile", EmBeColors.BrandOrange, Modifier.weight(1f)) { showEdit = true }
                }

                if (profile.languages.isNotEmpty()) {
                    Text("Languages", fontWeight = FontWeight.Bold)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        profile.languages.forEach { lang ->
                            Text(
                                lang,
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 13.sp,
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(EmBeColors.BrandOrange)
                                    .padding(horizontal = 10.dp, vertical = 6.dp),
                            )
                        }
                    }
                }

                if (profile.familyMembers.isNotEmpty()) {
                    Text("Family & Friends", fontWeight = FontWeight.Bold)
                    profile.familyMembers.forEach { member ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFFF7F8FB))
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                modifier = Modifier.size(40.dp).clip(CircleShape).background(member.avatarStyle.color),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(member.monogram, color = Color.White, fontWeight = FontWeight.Bold)
                            }
                            Column {
                                Text(member.displayName, fontWeight = FontWeight.SemiBold)
                                Text(
                                    member.preferredServices.take(2).joinToString(", ").ifEmpty { "—" },
                                    color = EmBeColors.MutedText,
                                    fontSize = 12.sp,
                                )
                            }
                        }
                    }
                }

                Text("Your bookings", fontWeight = FontWeight.Bold)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0xFFF0F1F4))
                        .padding(4.dp),
                ) {
                    BookingTab.entries.forEach { tab ->
                        val selected = bookingTab == tab
                        Text(
                            tab.shortTitle,
                            textAlign = TextAlign.Center,
                            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                            fontSize = 13.sp,
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (selected) Color.White else Color.Transparent)
                                .clickable { bookingTab = tab }
                                .padding(vertical = 10.dp),
                        )
                    }
                }

                val filtered = appViewModel.bookings.filter { it.status.tab == bookingTab }
                if (filtered.isEmpty()) {
                    Text("No ${bookingTab.title.lowercase()} bookings", color = EmBeColors.MutedText)
                } else {
                    filtered.take(5).forEach { booking ->
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(14.dp))
                                .background(Color(0xFFF6F7F9))
                                .clickable {
                                    if (booking.status == BookingStatus.Completed) {
                                        reviewProvider = booking.provider
                                    }
                                }
                                .padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp),
                        ) {
                            Text(booking.provider.name, fontWeight = FontWeight.Bold)
                            Text(booking.title, color = EmBeColors.MutedText, fontSize = 13.sp)
                            Text("${booking.status.name} · ${booking.date}", color = EmBeColors.MutedText, fontSize = 12.sp)
                        }
                    }
                }
            }
        }

        if (showEdit) {
            ProfileDetailEditScreen(
                appViewModel = appViewModel,
                onDismiss = { showEdit = false },
            )
        }
        if (showPayReceive) {
            PayReceiveScreen(onDismiss = { showPayReceive = false })
        }
        reviewProvider?.let { provider ->
            RateAndReviewScreen(
                provider = provider,
                appViewModel = appViewModel,
                onDismiss = { reviewProvider = null },
            )
        }
    }
}

@Composable
private fun EmptyProfileCard(onEdit: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Color(0xFFF7F8FB))
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Image(
            painterResource(R.drawable.katie_avatar),
            contentDescription = null,
            modifier = Modifier.size(72.dp).clip(CircleShape),
            contentScale = ContentScale.Crop,
        )
        Text("Complete your profile", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Text(
            "Add your contact details and care recipients so providers know who they’re supporting.",
            color = EmBeColors.MutedText,
            textAlign = TextAlign.Center,
            fontSize = 14.sp,
        )
        PrimaryOrangeButton(text = "Set up profile", onClick = onEdit)
    }
}

@Composable
private fun FilledProfileHeader(profile: UserProfile) {
    Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Box {
            Image(
                painterResource(R.drawable.katie_avatar),
                contentDescription = null,
                modifier = Modifier.size(72.dp).clip(CircleShape),
                contentScale = ContentScale.Crop,
            )
            if (profile.hasUploadedPhoto) {
                Icon(
                    Icons.Filled.Verified,
                    contentDescription = null,
                    tint = EmBeColors.LinkBlue,
                    modifier = Modifier.align(Alignment.BottomEnd).size(22.dp).background(Color.White, CircleShape),
                )
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(profile.displayFirstLast, fontWeight = FontWeight.Bold, fontSize = 22.sp)
            Text(profile.roleLabel, color = EmBeColors.MutedText)
            Text(profile.address, color = EmBeColors.MutedText, fontSize = 13.sp)
            Text("${profile.rating} ★ · ${profile.reviewCount} reviews", color = EmBeColors.MutedText, fontSize = 13.sp)
        }
    }
}

@Composable
private fun ActionChip(title: String, color: Color, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(color.copy(alpha = 0.12f))
            .clickable(onClick = onClick)
            .padding(vertical = 14.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (title.startsWith("Pay")) {
            Icon(Icons.Filled.QrCodeScanner, null, tint = color, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
        }
        Text(title, color = color, fontWeight = FontWeight.Bold, fontSize = 14.sp)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ProfileDetailEditScreen(
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    var draft by remember { mutableStateOf(appViewModel.profile.copy(familyMembers = appViewModel.profile.familyMembers.toList())) }
    var newFirst by remember { mutableStateOf("") }
    var newLast by remember { mutableStateOf("") }
    var isAdding by remember { mutableStateOf(false) }
    val languageOptions = listOf("English", "Spanish", "Mandarin", "Cantonese", "French", "ASL")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .statusBarsPadding(),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = "Back",
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFE8E9ED))
                    .clickable(onClick = onDismiss)
                    .padding(4.dp),
            )
            Spacer(modifier = Modifier.weight(1f))
            Text("Edit Profile", fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
            Spacer(modifier = Modifier.weight(1f))
            Text(
                "Done",
                color = if (draft.hasMinimumContact) Color.White else Color.White.copy(alpha = 0.6f),
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (draft.hasMinimumContact) EmBeColors.BrandOrange else EmBeColors.Grayscale60)
                    .clickable(enabled = draft.hasMinimumContact) {
                        appViewModel.publishProfile(draft)
                        onDismiss()
                    }
                    .padding(horizontal = 14.dp, vertical = 8.dp),
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            RequiredLabel("First name")
            OutlinedTextField(draft.firstName, { draft = draft.copy(firstName = it) }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            RequiredLabel("Last name")
            OutlinedTextField(draft.lastName, { draft = draft.copy(lastName = it) }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            RequiredLabel("Address")
            OutlinedTextField(draft.address, { draft = draft.copy(address = it) }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            Text("Email", color = EmBeColors.MutedText, fontSize = 12.sp)
            OutlinedTextField(draft.email, { draft = draft.copy(email = it) }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            Text("Mobile", color = EmBeColors.MutedText, fontSize = 12.sp)
            OutlinedTextField(draft.mobile, { draft = draft.copy(mobile = it) }, modifier = Modifier.fillMaxWidth(), singleLine = true)

            Text("Languages", fontWeight = FontWeight.Bold)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                languageOptions.forEach { lang ->
                    val selected = draft.languages.contains(lang)
                    Text(
                        lang,
                        color = if (selected) Color.White else EmBeColors.DarkText,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (selected) EmBeColors.BrandOrange else Color(0xFFF0F1F4))
                            .clickable {
                                draft = draft.copy(
                                    languages = if (selected) draft.languages - lang else draft.languages + lang,
                                )
                            }
                            .padding(horizontal = 10.dp, vertical = 8.dp),
                    )
                }
            }

            Text("Family & Friends", fontWeight = FontWeight.Bold)
            draft.familyMembers.forEach { member ->
                Text(
                    member.displayName,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color(0xFFF7F8FB))
                        .padding(12.dp),
                    fontWeight = FontWeight.SemiBold,
                )
            }

            if (isAdding) {
                OutlinedTextField(newFirst, { newFirst = it }, label = { Text("First name") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
                OutlinedTextField(newLast, { newLast = it }, label = { Text("Last name") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Cancel", color = EmBeColors.MutedText, modifier = Modifier.clickable {
                        isAdding = false
                        newFirst = ""
                        newLast = ""
                    }.padding(8.dp))
                    Text(
                        "Add",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .background(EmBeColors.BrandOrange)
                            .clickable(enabled = newFirst.isNotBlank() && newLast.isNotBlank()) {
                                val member = FamilyMember(
                                    firstName = newFirst.trim(),
                                    lastName = newLast.trim(),
                                    preferredServices = listOf("Personal care/ hygiene"),
                                    preferredTimes = listOf("8am – 10am"),
                                    avatarStyle = MemberAvatarStyle.next(after = draft.familyMembers.size),
                                )
                                draft = draft.copy(familyMembers = draft.familyMembers + member)
                                isAdding = false
                                newFirst = ""
                                newLast = ""
                            }
                            .padding(horizontal = 16.dp, vertical = 10.dp),
                    )
                }
            } else {
                Text(
                    "+ Add member",
                    color = EmBeColors.BrandOrange,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.clickable { isAdding = true }.padding(8.dp),
                )
            }
        }
    }
}

@Composable
private fun RequiredLabel(text: String) {
    Row {
        Text(text, color = EmBeColors.MutedText, fontSize = 12.sp)
        Text(" *", color = RequiredPink, fontSize = 12.sp)
    }
}
