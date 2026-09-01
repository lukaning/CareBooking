package com.embelife.app.ui.review

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.Provider
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import kotlinx.coroutines.delay
import java.util.UUID

private val StarGold = Color(0xFFFFC71F)
private val StarEmpty = Color(0xFFD0D4DC)

@Composable
fun StarRating(
    rating: Int,
    onRate: ((Int) -> Unit)? = null,
    starColor: Color = StarGold,
    size: Int = 28,
) {
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        (1..5).forEach { value ->
            Icon(
                imageVector = if (value <= rating) Icons.Filled.Star else Icons.Outlined.StarBorder,
                contentDescription = "$value stars",
                tint = if (value <= rating) starColor else StarEmpty,
                modifier = Modifier
                    .size(size.dp)
                    .then(if (onRate != null) Modifier.clickable { onRate(value) } else Modifier),
            )
        }
    }
}

@Composable
fun RateAndReviewScreen(
    provider: Provider,
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    var draftRating by remember { mutableIntStateOf(0) }
    var draftBody by remember { mutableStateOf("") }
    var showBanner by remember { mutableStateOf(false) }
    val reviews = appViewModel.reviews(provider.id)

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
                Text("Rate & Review", fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                Spacer(modifier = Modifier.weight(1f))
                Spacer(modifier = Modifier.size(36.dp))
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Text(provider.name, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = EmBeColors.DarkText)
                Text(provider.title, color = EmBeColors.MutedText)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    StarRating(rating = provider.rating.toInt().coerceIn(1, 5), starColor = EmBeColors.BrandOrange, size = 18)
                    Text("${provider.rating} · ${provider.reviewCount} reviews", color = EmBeColors.MutedText, fontSize = 13.sp)
                }

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color(0xFFF7F8FB))
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text("Leave a rating", fontWeight = FontWeight.Bold)
                    StarRating(rating = draftRating, onRate = { draftRating = it }, size = 36)
                    OutlinedTextField(
                        value = draftBody,
                        onValueChange = { draftBody = it },
                        placeholder = { Text("Share your experience…") },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 3,
                    )
                    PrimaryOrangeButton(
                        text = "Submit Review",
                        enabled = draftRating > 0,
                        onClick = {
                            appViewModel.addProviderReview(
                                providerID = provider.id,
                                rating = draftRating,
                                body = draftBody.ifBlank { "Great experience!" },
                                authorName = appViewModel.userName.ifEmpty { "You" },
                            )
                            draftRating = 0
                            draftBody = ""
                            showBanner = true
                        },
                    )
                }

                Text("Reviews", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                reviews.forEach { review ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color.White)
                            .padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier.size(36.dp).clip(CircleShape).background(review.avatarColor),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(review.authorName.first().toString(), color = Color.White, fontWeight = FontWeight.Bold)
                            }
                            Column(modifier = Modifier.weight(1f)) {
                                Text(review.authorName, fontWeight = FontWeight.SemiBold)
                                Text(review.relativeTime, color = EmBeColors.MutedText, fontSize = 12.sp)
                            }
                            StarRating(rating = review.rating, size = 14)
                        }
                        Text(review.body, color = EmBeColors.DarkText, fontSize = 14.sp)
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.clickable { appViewModel.toggleReviewLike(review.id) },
                            ) {
                                Icon(
                                    if (review.liked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                                    contentDescription = "Like",
                                    tint = if (review.liked) EmBeColors.BrandOrange else EmBeColors.MutedText,
                                    modifier = Modifier.size(18.dp),
                                )
                                Spacer(Modifier.size(4.dp))
                                Text("Like", color = EmBeColors.MutedText, fontSize = 13.sp)
                            }
                            Text("Reply", color = EmBeColors.LinkBlue, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        }

        if (showBanner) {
            LaunchedEffect(showBanner) {
                delay(1800)
                showBanner = false
            }
            Text(
                "Review submitted",
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(top = 56.dp)
                    .clip(RoundedCornerShape(50))
                    .background(EmBeColors.BrandOrange)
                    .padding(horizontal = 16.dp, vertical = 10.dp),
            )
        }
    }
}

@Composable
fun InlineBookingReviewComposer(
    bookingID: UUID,
    appViewModel: AppViewModel,
    onSubmitted: () -> Unit = {},
) {
    var rating by remember { mutableIntStateOf(0) }
    var text by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Color(0xFFF7F8FB))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("Rate this visit", fontWeight = FontWeight.Bold)
        StarRating(rating = rating, onRate = { rating = it }, size = 32)
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            placeholder = { Text("Optional comments") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 2,
        )
        PrimaryOrangeButton(
            text = "Submit",
            enabled = rating > 0,
            onClick = {
                appViewModel.submitBookingReview(bookingID, rating, text)
                onSubmitted()
            },
        )
    }
}
