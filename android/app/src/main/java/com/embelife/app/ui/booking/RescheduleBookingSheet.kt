package com.embelife.app.ui.booking

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircleOutline
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.DatePicker
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.Booking
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private val FieldLabel = Color(0xFF1A3373)
private val SoftBorder = Color(0xFFE6E8EE)
private val SlotHighlight = Color(0xFFEDF2FF)

private val wideDate: DateTimeFormatter = DateTimeFormatter.ofPattern("MMMM d, yyyy")
private val monthYear: DateTimeFormatter = DateTimeFormatter.ofPattern("MMMM yyyy")
private val slotTime: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a")

private enum class RescheduleStep { Pick, Review, Success }

private enum class RescheduleField { Date, Time }

/** Half-hour slots from 8:00 AM through 8:00 PM, matching the iOS generator. */
private val timeSlots: List<LocalTime> = (0 until 25).map {
    LocalTime.of(8 + it / 2, (it % 2) * 30)
}

/** Port of `RescheduleBookingSheet` — pick a slot, review, then submit the proposal. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RescheduleBookingSheet(
    booking: Booking,
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var step by remember { mutableStateOf(RescheduleStep.Pick) }
    var selectedField by remember { mutableStateOf(RescheduleField.Date) }
    var selectedDate by remember { mutableStateOf(booking.date) }
    var selectedSlotIndex by remember {
        mutableIntStateOf(
            timeSlots.indexOfFirst { it == booking.startTime.toLocalTime() }.takeIf { it >= 0 } ?: 2,
        )
    }
    var reason by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }

    val proposedStart = LocalDateTime.of(selectedDate, timeSlots[selectedSlotIndex])
    val canSubmit = proposedStart.isAfter(LocalDateTime.now())

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
    ) {
        Column(modifier = Modifier.navigationBarsPadding()) {
            RescheduleHeader(
                title = when (step) {
                    RescheduleStep.Pick -> "Propose New Time"
                    RescheduleStep.Review -> "Review Proposal"
                    RescheduleStep.Success -> "Proposal Sent"
                },
                subtitle = booking.provider.name.takeIf { step == RescheduleStep.Pick },
            )

            when (step) {
                RescheduleStep.Pick -> PickStep(
                    selectedField = selectedField,
                    onSelectField = { selectedField = it },
                    selectedDate = selectedDate,
                    onSelectDate = { selectedDate = it },
                    selectedSlotIndex = selectedSlotIndex,
                    onSelectSlot = { selectedSlotIndex = it },
                    durationMinutes = booking.durationMinutes,
                    canSubmit = canSubmit,
                    onNext = { step = RescheduleStep.Review },
                )

                RescheduleStep.Review -> ReviewStep(
                    booking = booking,
                    proposedStart = proposedStart,
                    reason = reason,
                    onReasonChange = { reason = it },
                    message = message,
                    onMessageChange = { message = it },
                    onBack = { step = RescheduleStep.Pick },
                    onSubmit = {
                        appViewModel.rescheduleBooking(
                            id = booking.id,
                            date = selectedDate,
                            startTime = proposedStart,
                            reason = reason,
                            message = message,
                        )
                        step = RescheduleStep.Success
                    },
                )

                RescheduleStep.Success -> SuccessStep(
                    providerName = booking.provider.name,
                    proposedStart = proposedStart,
                    onDone = onDismiss,
                )
            }
        }
    }
}

@Composable
private fun RescheduleHeader(title: String, subtitle: String?) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp, bottom = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(22.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(EmBeColors.BrandOrange),
        )
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = title,
                color = EmBeColors.DarkText,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
            )
            subtitle?.let {
                Text(text = it, color = EmBeColors.MutedText, fontSize = 15.sp)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PickStep(
    selectedField: RescheduleField,
    onSelectField: (RescheduleField) -> Unit,
    selectedDate: LocalDate,
    onSelectDate: (LocalDate) -> Unit,
    selectedSlotIndex: Int,
    onSelectSlot: (Int) -> Unit,
    durationMinutes: Int,
    canSubmit: Boolean,
    onNext: () -> Unit,
) {
    val start = timeSlots[selectedSlotIndex]
    val end = start.plusMinutes(durationMinutes.toLong())

    Column {
        Text(
            text = "Choose a day and time in the future you want to propose",
            color = EmBeColors.MutedText,
            fontSize = 15.sp,
            modifier = Modifier.padding(horizontal = 20.dp),
        )

        Column(
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SelectionCard(
                icon = Icons.Filled.CalendarToday,
                iconTint = EmBeColors.LinkBlue,
                label = "Date",
                value = selectedDate.format(wideDate),
                isActive = selectedField == RescheduleField.Date,
                onClick = { onSelectField(RescheduleField.Date) },
            )

            SelectionCard(
                icon = Icons.Filled.Schedule,
                iconTint = EmBeColors.MutedText,
                label = "Time",
                value = "${start.format(slotTime)} - ${end.format(slotTime)}",
                isActive = selectedField == RescheduleField.Time,
                onClick = { onSelectField(RescheduleField.Time) },
            )
        }

        Box(modifier = Modifier.heightIn(max = 380.dp)) {
            when (selectedField) {
                RescheduleField.Date -> {
                    val pickerState = rememberDatePickerState(
                        initialSelectedDateMillis = selectedDate
                            .atStartOfDay(ZoneId.systemDefault())
                            .toInstant()
                            .toEpochMilli(),
                    )
                    pickerState.selectedDateMillis?.let { millis ->
                        val picked = Instant.ofEpochMilli(millis)
                            .atZone(ZoneId.systemDefault())
                            .toLocalDate()
                        if (picked != selectedDate) onSelectDate(picked)
                    }
                    DatePicker(state = pickerState, title = null, headline = null)
                }

                RescheduleField.Time -> TimeSlotPicker(
                    selectedDate = selectedDate,
                    selectedSlotIndex = selectedSlotIndex,
                    durationMinutes = durationMinutes,
                    onSelectSlot = onSelectSlot,
                )
            }
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 20.dp),
        ) {
            PrimaryOrangeButton(text = "Next", enabled = canSubmit, onClick = onNext)
        }
    }
}

@Composable
private fun TimeSlotPicker(
    selectedDate: LocalDate,
    selectedSlotIndex: Int,
    durationMinutes: Int,
    onSelectSlot: (Int) -> Unit,
) {
    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = selectedDate.format(monthYear),
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "Clear",
                color = EmBeColors.LinkBlue,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { onSelectSlot(0) },
            )
        }

        HorizontalDivider(color = EmBeColors.CardBorder)

        Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
            timeSlots.forEachIndexed { index, slot ->
                val isSelected = index == selectedSlotIndex
                val end = slot.plusMinutes(durationMinutes.toLong())

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (isSelected) SlotHighlight else Color.Transparent)
                        .clickable { onSelectSlot(index) }
                        .padding(vertical = 14.dp, horizontal = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "${slot.format(slotTime)} - ${end.format(slotTime)}",
                        color = if (isSelected) EmBeColors.LinkBlue else EmBeColors.DarkText,
                        fontSize = 17.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    if (isSelected) {
                        Icon(
                            imageVector = Icons.Filled.Check,
                            contentDescription = null,
                            tint = EmBeColors.LinkBlue,
                            modifier = Modifier.size(20.dp),
                        )
                    }
                }

                if (index < timeSlots.lastIndex) {
                    HorizontalDivider(color = EmBeColors.CardBorder)
                }
            }
        }
    }
}

@Composable
private fun ReviewStep(
    booking: Booking,
    proposedStart: LocalDateTime,
    reason: String,
    onReasonChange: (String) -> Unit,
    message: String,
    onMessageChange: (String) -> Unit,
    onBack: () -> Unit,
    onSubmit: () -> Unit,
) {
    Column {
        Column(
            modifier = Modifier
                .heightIn(max = 460.dp)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = "Confirm the new time before sending it to ${booking.provider.name}.",
                color = EmBeColors.MutedText,
                fontSize = 15.sp,
            )

            ComparisonCard(
                title = "Current appointment",
                date = booking.date,
                start = booking.startTime,
                durationMinutes = booking.durationMinutes,
                isNew = false,
            )

            ComparisonCard(
                title = "Proposed appointment",
                date = proposedStart.toLocalDate(),
                start = proposedStart,
                durationMinutes = booking.durationMinutes,
                isNew = true,
            )

            LabeledField(
                label = "Reason for reschedule (optional)",
                value = reason,
                placeholder = "e.g. Schedule conflict",
                onValueChange = onReasonChange,
            )

            LabeledField(
                label = "Message to provider (optional)",
                value = message,
                placeholder = "Add a short note…",
                onValueChange = onMessageChange,
                minLines = 3,
                maxLines = 6,
            )
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            PrimaryOrangeButton(text = "Submit Proposal", onClick = onSubmit)
            Text(
                text = "Back",
                color = EmBeColors.MutedText,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable(onClick = onBack),
            )
        }
    }
}

@Composable
private fun SuccessStep(
    providerName: String,
    proposedStart: LocalDateTime,
    onDone: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            imageVector = Icons.Filled.CheckCircleOutline,
            contentDescription = null,
            tint = EmBeColors.BrandOrange,
            modifier = Modifier.size(56.dp),
        )
        Text(
            text = "Proposal sent",
            color = EmBeColors.DarkText,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = "$providerName will be notified about " +
                "${proposedStart.toLocalDate().format(wideDate)} at " +
                proposedStart.toLocalTime().format(slotTime) + ".",
            color = EmBeColors.MutedText,
            fontSize = 15.sp,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.size(8.dp))
        PrimaryOrangeButton(text = "Done", onClick = onDone)
    }
}

@Composable
private fun SelectionCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    iconTint: Color,
    label: String,
    value: String,
    isActive: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (isActive) Color(0xFFF7F9FC) else Color.White)
            .border(
                width = if (isActive) 2.dp else 1.dp,
                color = if (isActive) EmBeColors.LinkBlue else SoftBorder,
                shape = RoundedCornerShape(12.dp),
            )
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(24.dp),
        )
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = label, color = EmBeColors.MutedText, fontSize = 12.sp)
            Text(
                text = value,
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

@Composable
private fun ComparisonCard(
    title: String,
    date: LocalDate,
    start: LocalDateTime,
    durationMinutes: Int,
    isNew: Boolean,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Color(0xFFF8F9FB))
            .border(1.dp, SoftBorder, RoundedCornerShape(14.dp))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = title,
            color = if (isNew) EmBeColors.BrandOrange else EmBeColors.MutedText,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
        )

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.CalendarToday,
                contentDescription = null,
                tint = if (isNew) EmBeColors.LinkBlue else EmBeColors.MutedText,
                modifier = Modifier.size(20.dp),
            )
            Text(
                text = date.format(wideDate),
                color = EmBeColors.DarkText,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.Schedule,
                contentDescription = null,
                tint = if (isNew) EmBeColors.LinkBlue else EmBeColors.MutedText,
                modifier = Modifier.size(20.dp),
            )
            Text(
                text = "${start.toLocalTime().format(slotTime)} - " +
                    start.toLocalTime().plusMinutes(durationMinutes.toLong()).format(slotTime),
                color = EmBeColors.DarkText,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

@Composable
private fun LabeledField(
    label: String,
    value: String,
    placeholder: String,
    onValueChange: (String) -> Unit,
    minLines: Int = 1,
    maxLines: Int = 1,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = label,
            color = FieldLabel,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
        )
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = {
                Text(text = placeholder, color = EmBeColors.Grayscale60, fontSize = 15.sp)
            },
            minLines = minLines,
            maxLines = maxLines,
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
