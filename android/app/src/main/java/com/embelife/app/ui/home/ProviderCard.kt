package com.embelife.app.ui.home

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.embelife.app.model.Provider
import com.embelife.app.ui.theme.EmBeColors

private val MenuBorder = Color(0xFFE6E8EE)
private val IconButtonBorder = Color(0xFFE0E0E0)

/** Port of `ProviderCard`. */
@Composable
fun ProviderCard(
    provider: Provider,
    isBookingMenuExpanded: Boolean,
    onToggleBookingMenu: () -> Unit,
    onSelectAppointmentType: (BookingAppointmentType) -> Unit,
    onRatingTap: () -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 2.dp,
        modifier = Modifier
            .fillMaxWidth()
            .zIndex(if (isBookingMenuExpanded) 1000f else 0f),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Image(
                    painter = painterResource(provider.imageRes),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape),
                )

                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = provider.name,
                        color = EmBeColors.DarkText,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = provider.title,
                            color = EmBeColors.DarkText,
                            fontSize = 15.sp,
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Text(
                            text = "$${provider.ratePerHour}/hour",
                            color = EmBeColors.DarkText,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                }
            }

            HorizontalDivider(color = EmBeColors.CardBorder)

            Text(
                text = buildAnnotatedString {
                    withStyle(SpanStyle(color = EmBeColors.DarkText)) { append(provider.bio) }
                    append(" ")
                    withStyle(
                        SpanStyle(
                            color = EmBeColors.BrandOrange,
                            fontWeight = FontWeight.Bold,
                        ),
                    ) {
                        append("More details")
                    }
                },
                fontSize = 17.sp,
            )

            Text(
                text = provider.specialties,
                color = EmBeColors.MutedText,
                fontSize = 15.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )

            Box {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    CardIconButton(Icons.Filled.MoreHoriz)
                    // FaceTime-style video marker, matching the iOS tint.
                    CardIconButton(Icons.Filled.Videocam, tint = EmBeColors.LinkBlue)

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(14.dp))
                            .background(EmBeColors.BrandOrange)
                            .clickable(onClick = onToggleBookingMenu)
                            .padding(vertical = 14.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = "Book Now",
                            color = Color.White,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }

                if (isBookingMenuExpanded) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(top = 54.dp)
                            .zIndex(30f),
                    ) {
                        BookingTypeMenu(onSelect = onSelectAppointmentType)
                    }
                }
            }

            HorizontalDivider(color = EmBeColors.CardBorder)

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onRatingTap),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ProviderRatingLabel(
                    rating = provider.rating,
                    reviewCount = provider.reviewCount,
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = "Reviews",
                    tint = EmBeColors.MutedText,
                    modifier = Modifier.size(18.dp),
                )
            }
        }
    }
}

/** Port of `ProviderRatingLabel`. */
@Composable
fun ProviderRatingLabel(
    rating: Double,
    reviewCount: Int,
    compact: Boolean = false,
) {
    val size = if (compact) 12.sp else 15.sp
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(
            imageVector = Icons.Filled.Star,
            contentDescription = null,
            tint = EmBeColors.BrandOrange,
            modifier = Modifier.size(if (compact) 14.dp else 18.dp),
        )
        Text(
            text = String.format("%.1f", rating),
            color = EmBeColors.DarkText,
            fontSize = size,
            fontWeight = FontWeight.SemiBold,
        )
        Text(
            text = "($reviewCount reviews)",
            color = EmBeColors.MutedText,
            fontSize = size,
        )
    }
}

@Composable
private fun BookingTypeMenu(onSelect: (BookingAppointmentType) -> Unit) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        shadowElevation = 8.dp,
        modifier = Modifier
            .width(240.dp)
            .border(1.dp, MenuBorder, RoundedCornerShape(14.dp)),
    ) {
        Column {
            BookingTypeRow(
                title = "Book an in-person Appointment",
                onClick = { onSelect(BookingAppointmentType.InPerson) },
            )
            HorizontalDivider(color = MenuBorder, modifier = Modifier.padding(start = 14.dp))
            BookingTypeRow(
                title = "Book a Video Appointment",
                onClick = { onSelect(BookingAppointmentType.Video) },
            )
        }
    }
}

@Composable
private fun BookingTypeRow(title: String, onClick: () -> Unit) {
    Text(
        text = title,
        color = EmBeColors.DarkText,
        fontSize = 15.sp,
        fontWeight = FontWeight.Medium,
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 14.dp),
    )
}

@Composable
private fun CardIconButton(icon: ImageVector, tint: Color = EmBeColors.DarkText) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(RoundedCornerShape(14.dp))
            .border(1.dp, IconButtonBorder, RoundedCornerShape(14.dp))
            .clickable { },
        contentAlignment = Alignment.Center,
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint)
    }
}
