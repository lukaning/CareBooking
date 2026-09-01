package com.embelife.app.ui.booking

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
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
import androidx.compose.material.icons.automirrored.filled.ListAlt
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Forum
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.model.Booking
import com.embelife.app.model.BookingStatus
import com.embelife.app.model.BookingTab
import com.embelife.app.ui.home.ProviderRatingLabel
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

private val HeadingColor = Color(0xFF1F242E)
private val MutedColor = Color(0xFF737A8F)
private val IconMuted = Color(0xFF6B7385)
private val ModalCardBG = Color(0xFFF6F7F9)
private val CancelFill = Color(0xFFE8EAF0)
private val PurpleAccent = Color(0xFF7A6BC7)
private val SegmentTrack = Color(0xFFF0F1F4)
private val SegmentInactiveText = Color(0xFF738294)
private val SegmentDivider = Color(0xFFDBE0E8)

private val dayMonthYear: DateTimeFormatter = DateTimeFormatter.ofPattern("d MMM, yyyy")
private val clockFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("hh:mm a")

/** Port of `BookingsView` — the booking inbox reached from the Home calendar entry. */
@Composable
fun BookingsScreen(
    appViewModel: AppViewModel,
    contentPadding: PaddingValues,
    initialTab: BookingTab = BookingTab.Booked,
) {
    var bookingTab by remember { mutableStateOf(initialTab) }
    var expandedBookingID by remember { mutableStateOf<UUID?>(null) }
    var bookingToCancel by remember { mutableStateOf<Booking?>(null) }
    var bookingToReschedule by remember { mutableStateOf<Booking?>(null) }

    LaunchedEffect(Unit) { appViewModel.seedBookingsIfNeeded() }

    val filtered = appViewModel.bookings.filter { it.status.tab == bookingTab }

    LaunchedEffect(bookingTab, filtered.size) {
        if (expandedBookingID == null || filtered.none { it.id == expandedBookingID }) {
            expandedBookingID = filtered.firstOrNull()?.id
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(bottom = contentPadding.calculateBottomPadding()),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(vertical = 12.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = bookingTab.title,
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(top = 12.dp, bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            BookingSegmentControl(
                selected = bookingTab,
                onSelect = { bookingTab = it },
            )

            if (filtered.isEmpty()) {
                EmptyBookingsState(tab = bookingTab)
            } else {
                filtered.forEach { booking ->
                    BookingCard(
                        booking = booking,
                        isExpanded = expandedBookingID == booking.id,
                        onToggle = {
                            expandedBookingID =
                                if (expandedBookingID == booking.id) null else booking.id
                        },
                        onCancel = { bookingToCancel = booking },
                        onReschedule = { bookingToReschedule = booking },
                    )
                }
            }
        }
    }

    bookingToCancel?.let { booking ->
        CancelBookingSheet(
            booking = booking,
            appViewModel = appViewModel,
            onDismiss = { bookingToCancel = null },
            onCancelled = {
                if (expandedBookingID == booking.id) expandedBookingID = null
            },
        )
    }

    bookingToReschedule?.let { booking ->
        RescheduleBookingSheet(
            booking = booking,
            appViewModel = appViewModel,
            onDismiss = { bookingToReschedule = null },
        )
    }
}

@Composable
private fun BookingSegmentControl(
    selected: BookingTab,
    onSelect: (BookingTab) -> Unit,
) {
    val tabs = BookingTab.entries

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(SegmentTrack)
            .padding(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        tabs.forEachIndexed { index, tab ->
            val isSelected = selected == tab
            val nextSelected = index + 1 < tabs.size && selected == tabs[index + 1]

            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (isSelected) Color.White else Color.Transparent)
                    .clickable { onSelect(tab) }
                    .padding(vertical = 11.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = tab.shortTitle,
                    color = if (isSelected) HeadingColor else SegmentInactiveText,
                    fontSize = 14.sp,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                )
            }

            // Divider shows only between two inactive neighbours.
            if (index < tabs.size - 1) {
                Box(
                    modifier = Modifier
                        .width(1.dp)
                        .height(16.dp)
                        .background(
                            if (isSelected || nextSelected) Color.Transparent else SegmentDivider,
                        ),
                )
            }
        }
    }
}

@Composable
private fun EmptyBookingsState(tab: BookingTab) {
    val subtitle = when (tab) {
        BookingTab.Requested -> "You don't have any Request yet"
        BookingTab.Booked -> "You don't have any Booked appointments yet"
        BookingTab.Completed -> "You don't have any Completed bookings yet"
    }

    Surface(
        shape = RoundedCornerShape(20.dp),
        color = Color.White,
        shadowElevation = 4.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 48.dp, horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                painter = painterResource(R.drawable.empty_bookings),
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = Modifier.size(64.dp),
            )
            Text(
                text = "No booking ${tab.title}!",
                color = HeadingColor,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = subtitle,
                color = MutedColor,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun BookingCard(
    booking: Booking,
    isExpanded: Boolean,
    onToggle: () -> Unit,
    onCancel: () -> Unit,
    onReschedule: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(ModalCardBG)
            .padding(16.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onToggle)
                .padding(bottom = if (isExpanded) 8.dp else 0.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Box(
                modifier = Modifier
                    .width(5.dp)
                    .height(26.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(PurpleAccent.copy(alpha = 0.85f)),
            )

            Text(
                text = booking.status.name,
                color = HeadingColor,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
            )

            Spacer(modifier = Modifier.weight(1f))

            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(CancelFill),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = if (isExpanded) Icons.Filled.ExpandMore else Icons.Filled.ExpandLess,
                    contentDescription = null,
                    tint = IconMuted,
                    modifier = Modifier.size(16.dp),
                )
            }
        }

        if (isExpanded) {
            BookingDetails(
                booking = booking,
                onCancel = onCancel,
                onReschedule = onReschedule,
            )
        }
    }
}

@Composable
private fun BookingDetails(
    booking: Booking,
    onCancel: () -> Unit,
    onReschedule: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Here is your upcoming appointment with ${booking.provider.name}",
            color = MutedColor,
            fontSize = 14.sp,
            modifier = Modifier.padding(bottom = 4.dp),
        )

        BookingProviderCard(booking)

        FloatingCard {
            DetailRow(
                icon = Icons.Filled.CalendarToday,
                label = "Date",
                value = formattedDate(booking.date),
            )
        }

        FloatingCard {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Icon(
                        imageVector = Icons.Filled.Schedule,
                        contentDescription = null,
                        tint = IconMuted,
                        modifier = Modifier.size(22.dp),
                    )
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(text = "Time", color = MutedColor, fontSize = 13.sp)
                        Text(
                            text = durationLabel(booking.durationMinutes),
                            color = HeadingColor,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                        )
                        Text(
                            text = "Start at ${booking.startTime.format(clockFormatter)}",
                            color = HeadingColor,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                        )
                        Text(
                            text = "End at ${booking.endTime.format(clockFormatter)}",
                            color = HeadingColor,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }

                if (booking.status != BookingStatus.Completed) {
                    BookingActionRow(
                        onCancel = onCancel,
                        onReschedule = onReschedule,
                    )
                }
            }
        }

        if (booking.serviceProvidedTo.isNotEmpty()) {
            FloatingCard {
                DetailRow(
                    icon = Icons.Filled.Forum,
                    label = "Services provided to",
                    value = booking.serviceProvidedTo,
                )
            }
        }

        FloatingCard {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ListAlt,
                    contentDescription = null,
                    tint = IconMuted,
                    modifier = Modifier.size(22.dp),
                )
                Text(
                    text = "Checklist Details",
                    color = HeadingColor,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = IconMuted,
                    modifier = Modifier.size(18.dp),
                )
            }
        }

        if (booking.status == BookingStatus.Requested || booking.status == BookingStatus.Booked) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(EmBeColors.BrandOrange)
                    .clickable { }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "Add Task",
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

@Composable
private fun BookingActionRow(
    onCancel: () -> Unit,
    onReschedule: () -> Unit,
) {
    var menuExpanded by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(12.dp))
                .background(CancelFill)
                .clickable(onClick = onCancel)
                .padding(vertical = 14.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "Cancel",
                color = HeadingColor,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
            )
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(12.dp))
                .background(EmBeColors.BrandOrange),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clickable(onClick = onReschedule)
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "Modify",
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                )
            }

            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(22.dp)
                    .background(Color.White.copy(alpha = 0.35f)),
            )

            Box {
                Box(
                    modifier = Modifier
                        .width(44.dp)
                        .clickable { menuExpanded = true }
                        .padding(vertical = 14.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.Filled.ExpandMore,
                        contentDescription = "More booking actions",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp),
                    )
                }

                DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                    DropdownMenuItem(
                        text = { Text("Reschedule") },
                        onClick = {
                            menuExpanded = false
                            onReschedule()
                        },
                    )
                    DropdownMenuItem(
                        text = { Text("Edit booking") },
                        onClick = { menuExpanded = false },
                    )
                    DropdownMenuItem(
                        text = { Text("Cancel booking", color = EmBeColors.ErrorCoral) },
                        onClick = {
                            menuExpanded = false
                            onCancel()
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun BookingProviderCard(booking: Booking) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        shadowElevation = 3.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Image(
                painter = painterResource(booking.provider.imageRes),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(52.dp)
                    .clip(CircleShape),
            )

            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(3.dp),
            ) {
                Text(
                    text = booking.provider.name,
                    color = HeadingColor,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(text = booking.provider.title, color = MutedColor, fontSize = 13.sp)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    ProviderRatingLabel(
                        rating = booking.provider.rating,
                        reviewCount = booking.provider.reviewCount,
                        compact = true,
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "$${booking.provider.ratePerHour}/hour",
                        color = HeadingColor,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }
    }
}

@Composable
private fun FloatingCard(content: @Composable () -> Unit) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        shadowElevation = 3.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Box(modifier = Modifier.padding(14.dp)) { content() }
    }
}

@Composable
private fun DetailRow(icon: ImageVector, label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = IconMuted,
            modifier = Modifier.size(22.dp),
        )
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = label, color = MutedColor, fontSize = 13.sp)
            Text(
                text = value,
                color = HeadingColor,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

internal fun formattedDate(date: LocalDate): String = date.format(dayMonthYear)

internal fun clockTime(time: LocalDateTime): String = time.format(clockFormatter)

internal fun durationLabel(minutes: Int): String = when {
    minutes % 60 == 0 -> {
        val hours = minutes / 60
        if (hours == 1) "1 hour" else "$hours hours"
    }

    minutes > 60 -> "${minutes / 60}h ${minutes % 60} min"
    else -> "$minutes min"
}
