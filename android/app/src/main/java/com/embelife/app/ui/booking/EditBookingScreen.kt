package com.embelife.app.ui.booking

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.Icon
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.Booking
import com.embelife.app.model.BookingChecklistTask
import com.embelife.app.model.BookingStatus
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import java.time.format.DateTimeFormatter
import java.util.UUID

private val BodyDark = Color(0xFF1F242E)
private val LabelMuted = Color(0xFF737A8F)
private val SoftBorder = Color(0xFFE6E8EE)
private val CardFill = Color(0xFFFCFCFC)
private val IconMuted = Color(0xFF6B7385)

private val CreatedFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")
private val DateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("d MMM, yyyy")
private val TimeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a")

/**
 * Port of `EditBookingView` — checklist details with optional edit mode.
 */
@Composable
fun EditBookingScreen(
    bookingID: UUID,
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    val booking = appViewModel.booking(bookingID)
    var isEditing by remember { mutableStateOf(false) }
    var showReschedule by remember { mutableStateOf(false) }
    var showCancelConfirm by remember { mutableStateOf(false) }
    var showAddTask by remember { mutableStateOf(false) }
    var addSubtaskParentID by remember { mutableStateOf<UUID?>(null) }
    var taskToEdit by remember { mutableStateOf<BookingChecklistTask?>(null) }
    var showSavedBanner by remember { mutableStateOf(false) }
    var bannerMessage by remember { mutableStateOf("Booking updated") }

    var draftTitle by remember { mutableStateOf("") }
    var draftDescription by remember { mutableStateOf("") }
    var draftServiceProvidedTo by remember { mutableStateOf("") }
    var draftLocation by remember { mutableStateOf("") }
    var draftDurationMinutes by remember { mutableIntStateOf(120) }

    LaunchedEffect(booking?.id) {
        booking?.let {
            draftTitle = it.title
            draftDescription = it.taskDescription
            draftServiceProvidedTo = it.serviceProvidedTo
            draftLocation = it.location
            draftDurationMinutes = it.durationMinutes
        }
    }

    if (booking == null) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .statusBarsPadding()
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("Booking Not Found", color = BodyDark, fontSize = 18.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                "Back",
                color = EmBeColors.LinkBlue,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable(onClick = onDismiss),
            )
        }
        return
    }

    Box(modifier = Modifier.fillMaxSize().background(Color.White)) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = "Back",
                    tint = BodyDark,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFE8E9ED))
                        .clickable(onClick = onDismiss)
                        .padding(6.dp),
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    "Checklist Details",
                    color = BodyDark,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(modifier = Modifier.weight(1f))
                if (booking.status != BookingStatus.Completed) {
                    Icon(
                        if (isEditing) Icons.Filled.Check else Icons.Filled.Edit,
                        contentDescription = if (isEditing) "Save" else "Edit",
                        tint = EmBeColors.LinkBlue,
                        modifier = Modifier
                            .size(32.dp)
                            .clickable {
                                if (isEditing) {
                                    appViewModel.updateBooking(
                                        booking.copy(
                                            title = draftTitle,
                                            taskDescription = draftDescription,
                                            serviceProvidedTo = draftServiceProvidedTo,
                                            location = draftLocation,
                                            durationMinutes = draftDurationMinutes,
                                        ),
                                    )
                                    bannerMessage = "Booking updated"
                                    showSavedBanner = true
                                    isEditing = false
                                } else {
                                    isEditing = true
                                }
                            }
                            .padding(4.dp),
                    )
                } else {
                    Spacer(modifier = Modifier.size(32.dp))
                }
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                HeaderSection(
                    booking = booking,
                    isEditing = isEditing,
                    draftTitle = draftTitle,
                    draftDescription = draftDescription,
                    onTitleChange = { draftTitle = it },
                    onDescriptionChange = { draftDescription = it },
                )

                DetailCards(
                    booking = booking,
                    isEditing = isEditing,
                    draftServiceProvidedTo = draftServiceProvidedTo,
                    draftLocation = draftLocation,
                    draftDurationMinutes = draftDurationMinutes,
                    onServiceChange = { draftServiceProvidedTo = it },
                    onLocationChange = { draftLocation = it },
                    onDurationChange = { draftDurationMinutes = it },
                    onChangeSchedule = { showReschedule = true },
                )

                ChecklistSection(
                    tasks = booking.checklistTasks,
                    canEdit = booking.status != BookingStatus.Completed,
                    onAddTask = { showAddTask = true },
                    onEditTask = { taskToEdit = it },
                    onAddSubtask = { addSubtaskParentID = it },
                    onRemoveTask = { appViewModel.removeChecklistTask(bookingID, it) },
                    onSaveForNext = { appViewModel.saveTaskForNextTime(it) },
                )

                if (booking.status != BookingStatus.Completed) {
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(
                            "Cancel booking",
                            color = EmBeColors.ErrorCoral,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFFE8EAF0))
                                .clickable { showCancelConfirm = true }
                                .padding(vertical = 14.dp),
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        )
                        if (isEditing) {
                            Box(modifier = Modifier.weight(1f)) {
                                PrimaryOrangeButton(
                                    text = "Save",
                                    onClick = {
                                        appViewModel.updateBooking(
                                            booking.copy(
                                                title = draftTitle,
                                                taskDescription = draftDescription,
                                                serviceProvidedTo = draftServiceProvidedTo,
                                                location = draftLocation,
                                                durationMinutes = draftDurationMinutes,
                                            ),
                                        )
                                        bannerMessage = "Booking updated"
                                        showSavedBanner = true
                                        isEditing = false
                                    },
                                )
                            }
                        }
                    }
                }
            }
        }

        if (showSavedBanner) {
            LaunchedEffect(showSavedBanner) {
                kotlinx.coroutines.delay(1800)
                showSavedBanner = false
            }
            Text(
                text = bannerMessage,
                color = Color.White,
                fontSize = 14.sp,
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

    if (showReschedule) {
        RescheduleBookingSheet(
            booking = booking,
            appViewModel = appViewModel,
            onDismiss = { showReschedule = false },
        )
    }

    if (showCancelConfirm) {
        CancelBookingSheet(
            booking = booking,
            appViewModel = appViewModel,
            onDismiss = { showCancelConfirm = false },
            onCancelled = onDismiss,
        )
    }

    if (showAddTask) {
        AddTaskToBookingSheet(
            bookingID = bookingID,
            appViewModel = appViewModel,
            onDismiss = { showAddTask = false },
        )
    }

    taskToEdit?.let { task ->
        AddTaskToBookingSheet(
            bookingID = bookingID,
            appViewModel = appViewModel,
            editingTask = task,
            onDismiss = { taskToEdit = null },
        )
    }

    addSubtaskParentID?.let { parentID ->
        AddTaskToBookingSheet(
            bookingID = bookingID,
            appViewModel = appViewModel,
            parentTaskID = parentID,
            onDismiss = { addSubtaskParentID = null },
        )
    }
}

@Composable
private fun HeaderSection(
    booking: Booking,
    isEditing: Boolean,
    draftTitle: String,
    draftDescription: String,
    onTitleChange: (String) -> Unit,
    onDescriptionChange: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        if (isEditing) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Title", color = LabelMuted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                OutlinedTextField(
                    value = draftTitle,
                    onValueChange = onTitleChange,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = SoftBorder,
                        unfocusedBorderColor = SoftBorder,
                    ),
                )
            }
        } else {
            Text(booking.title, color = BodyDark, fontSize = 22.sp, fontWeight = FontWeight.SemiBold)
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Description", color = BodyDark, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            if (isEditing) {
                OutlinedTextField(
                    value = draftDescription,
                    onValueChange = onDescriptionChange,
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = SoftBorder,
                        unfocusedBorderColor = SoftBorder,
                    ),
                )
            } else {
                Text(booking.taskDescription, color = EmBeColors.Grayscale60, fontSize = 14.sp)
            }
        }

        Row {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Provider", color = BodyDark, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Image(
                        painter = painterResource(booking.provider.imageRes),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(36.dp).clip(CircleShape),
                    )
                    Text(booking.provider.name, color = BodyDark, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Box(
                modifier = Modifier
                    .padding(horizontal = 12.dp)
                    .width(1.dp)
                    .height(56.dp)
                    .background(SoftBorder),
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Date Created", color = BodyDark, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.CalendarToday, contentDescription = null, tint = IconMuted, modifier = Modifier.size(16.dp))
                    Text(booking.dateCreated.format(CreatedFormatter), color = BodyDark, fontSize = 14.sp)
                }
            }
        }
    }
}

@Composable
private fun DetailCards(
    booking: Booking,
    isEditing: Boolean,
    draftServiceProvidedTo: String,
    draftLocation: String,
    draftDurationMinutes: Int,
    onServiceChange: (String) -> Unit,
    onLocationChange: (String) -> Unit,
    onDurationChange: (Int) -> Unit,
    onChangeSchedule: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        if (isEditing) {
            DetailCard(icon = Icons.Filled.Edit, label = "Services provided to") {
                OutlinedTextField(
                    value = draftServiceProvidedTo,
                    onValueChange = onServiceChange,
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                )
            }
        } else if (booking.serviceProvidedTo.isNotEmpty()) {
            DetailCard(icon = Icons.Filled.Edit, label = "Services provided to") {
                Text(booking.serviceProvidedTo, color = BodyDark, fontWeight = FontWeight.SemiBold)
            }
        }

        DetailCard(icon = Icons.Filled.CalendarToday, label = "Date") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(booking.date.format(DateFormatter), color = BodyDark, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                if (isEditing) {
                    Text(
                        "Change",
                        color = EmBeColors.LinkBlue,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable(onClick = onChangeSchedule),
                    )
                }
            }
        }

        DetailCard(icon = Icons.Filled.Schedule, label = "Time") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "${booking.startTime.format(TimeFormatter)} – ${booking.endTime.format(TimeFormatter)}",
                    color = BodyDark,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                )
                if (isEditing) {
                    Text(
                        "Change",
                        color = EmBeColors.LinkBlue,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable(onClick = onChangeSchedule),
                    )
                }
            }
        }

        if (isEditing) {
            DetailCard(icon = Icons.Filled.Schedule, label = "Duration") {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(30, 60, 90, 120, 150, 180).forEach { minutes ->
                        val selected = draftDurationMinutes == minutes
                        Text(
                            text = if (minutes < 60) "${minutes}m" else "${minutes / 60}h",
                            color = if (selected) Color.White else BodyDark,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(if (selected) EmBeColors.BrandOrange else Color(0xFFF0F1F4))
                                .clickable { onDurationChange(minutes) }
                                .padding(horizontal = 10.dp, vertical = 8.dp),
                        )
                    }
                }
            }
            DetailCard(icon = Icons.Filled.Edit, label = "Location") {
                OutlinedTextField(
                    value = draftLocation,
                    onValueChange = onLocationChange,
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                )
            }
        } else {
            DetailCard(icon = Icons.Filled.Edit, label = "Location") {
                Text(booking.location, color = BodyDark, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun DetailCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    content: @Composable () -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = CardFill,
        shadowElevation = 2.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, contentDescription = null, tint = IconMuted, modifier = Modifier.size(16.dp))
                Text(label, color = LabelMuted, fontSize = 12.sp)
            }
            content()
        }
    }
}

@Composable
private fun ChecklistSection(
    tasks: List<BookingChecklistTask>,
    canEdit: Boolean,
    onAddTask: () -> Unit,
    onEditTask: (BookingChecklistTask) -> Unit,
    onAddSubtask: (UUID) -> Unit,
    onRemoveTask: (UUID) -> Unit,
    onSaveForNext: (BookingChecklistTask) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Checklist", color = BodyDark, fontSize = 20.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            if (canEdit) {
                Icon(
                    Icons.Filled.Add,
                    contentDescription = "Add Task",
                    tint = Color.White,
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(EmBeColors.BrandOrange)
                        .clickable(onClick = onAddTask)
                        .padding(4.dp),
                )
            }
        }

        if (tasks.isEmpty()) {
            Text("No checklist tasks yet", color = LabelMuted, fontSize = 14.sp)
        } else {
            tasks.forEach { task ->
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = Color.White,
                    shadowElevation = 2.dp,
                    modifier = Modifier
                        .fillMaxWidth()
                        .then(
                            if (canEdit) Modifier.clickable { onEditTask(task) } else Modifier,
                        ),
                ) {
                    Column(
                        modifier = Modifier.padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Icon(Icons.Filled.CheckBoxOutlineBlank, contentDescription = null, tint = IconMuted)
                            Column(modifier = Modifier.weight(1f)) {
                                Text(task.title, color = BodyDark, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                                Text(task.categoryPathLabel, color = LabelMuted, fontSize = 12.sp)
                                task.scheduleSubtitle?.let {
                                    Text(it, color = LabelMuted, fontSize = 12.sp)
                                }
                            }
                            if (canEdit) {
                                Icon(
                                    Icons.Filled.Delete,
                                    contentDescription = "Remove",
                                    tint = EmBeColors.ErrorCoral,
                                    modifier = Modifier
                                        .size(18.dp)
                                        .clickable { onRemoveTask(task.id) },
                                )
                            }
                        }
                        task.subtasks.forEach { sub ->
                            Row(
                                modifier = Modifier.padding(start = 28.dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Icon(Icons.Filled.CheckBoxOutlineBlank, contentDescription = null, tint = LabelMuted, modifier = Modifier.size(16.dp))
                                Text(sub.title, color = BodyDark, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                            }
                        }
                        if (canEdit) {
                            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                                Text(
                                    "+ Sub-task",
                                    color = EmBeColors.LinkBlue,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    modifier = Modifier.clickable { onAddSubtask(task.id) },
                                )
                                Text(
                                    "Save for next time",
                                    color = EmBeColors.MutedText,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    modifier = Modifier.clickable { onSaveForNext(task) },
                                )
                            }
                        }
                    }
                }
            }
        }

        if (canEdit) {
            PrimaryOrangeButton(text = "Add Task", onClick = onAddTask)
        }
    }
}
