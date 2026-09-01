package com.embelife.app.ui.booking

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
import com.embelife.app.model.BookingChecklistTask
import com.embelife.app.ui.theme.EmBeColors

private val SoftBorder = Color(0xFFE6E8EE)
private val FieldStroke = Color(0xFFE0E3E8)

/** Port of `AddTaskNavHeader`. */
@Composable
fun AddTaskNavHeader(
    title: String,
    doneEnabled: Boolean = true,
    onBack: () -> Unit,
    onDone: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(top = 8.dp, bottom = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
            contentDescription = "Back",
            tint = EmBeColors.DarkText,
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(Color.White)
                .border(1.dp, SoftBorder, CircleShape)
                .clickable(onClick = onBack)
                .padding(6.dp),
        )
        Spacer(modifier = Modifier.weight(1f))
        Text(
            text = title,
            color = EmBeColors.DarkText,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
        )
        Spacer(modifier = Modifier.weight(1f))
        Text(
            text = "Done",
            color = Color.White,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(EmBeColors.BrandOrange.copy(alpha = if (doneEnabled) 1f else 0.45f))
                .clickable(enabled = doneEnabled, onClick = onDone)
                .padding(horizontal = 18.dp, vertical = 9.dp),
        )
    }
}

/** Port of `SubtaskListSection`. */
@Composable
fun SubtaskListSection(
    subtasks: List<BookingChecklistTask>,
    onAdd: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Sub-Task",
            color = EmBeColors.DarkText,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
        )

        if (subtasks.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, FieldStroke, RoundedCornerShape(14.dp))
                    .padding(vertical = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    text = "No Sub-Task added",
                    color = EmBeColors.DarkText,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = "Subtitle goes here",
                    color = EmBeColors.MutedText,
                    fontSize = 14.sp,
                )
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                subtasks.forEach { task ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color.White)
                            .border(1.dp, FieldStroke, RoundedCornerShape(14.dp))
                            .padding(14.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Filled.CheckBoxOutlineBlank,
                            contentDescription = null,
                            tint = EmBeColors.MutedText,
                        )
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = task.title,
                                color = EmBeColors.DarkText,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                            val subtitle = task.scheduleSubtitle
                                ?: task.detailDescription.takeIf { it.isNotEmpty() }
                            if (subtitle != null) {
                                Text(text = subtitle, color = EmBeColors.MutedText, fontSize = 12.sp)
                            }
                        }
                    }
                }
            }
        }

        Text(
            text = "Add Sub-Task",
            color = Color.White,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFF2E2E33))
                .clickable(onClick = onAdd)
                .padding(vertical = 16.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )
    }
}

/** Port of `AddSubTaskComposerView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddSubTaskComposerSheet(
    onCancel: () -> Unit,
    onSave: (BookingChecklistTask) -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var name by remember { mutableStateOf("") }
    var descriptionText by remember { mutableStateOf("") }
    var estimatedLabel by remember { mutableStateOf("") }
    var showTimePicker by remember { mutableStateOf(false) }
    var showValidation by remember { mutableStateOf(false) }

    val canSave = name.trim().isNotEmpty()

    ModalBottomSheet(
        onDismissRequest = onCancel,
        sheetState = sheetState,
        containerColor = Color(0xFFF5F5F7),
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 28.dp),
        ) {
            AddTaskNavHeader(
                title = "Add Sub-Task",
                doneEnabled = canSave,
                onBack = onCancel,
                onDone = {
                    if (!canSave) {
                        showValidation = true
                        return@AddTaskNavHeader
                    }
                    onSave(
                        BookingChecklistTask(
                            title = name.trim(),
                            category = "Sub-task",
                            detailDescription = descriptionText.trim(),
                            estimatedMinutes = BookingChecklistTask.minutesFromEstimateLabel(estimatedLabel),
                        ),
                    )
                },
            )

            Column(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        imageVector = Icons.Filled.Checklist,
                        contentDescription = null,
                        tint = EmBeColors.MutedText,
                    )
                    Text(text = "Task Details", color = EmBeColors.MutedText, fontSize = 14.sp)
                }

                ComposerField(label = "Sub-Task Name", value = name, onValueChange = {
                    name = it
                    showValidation = false
                }, placeholder = "Name this sub-task")

                ComposerField(
                    label = "Description",
                    value = descriptionText,
                    onValueChange = { descriptionText = it },
                    placeholder = "Optional details",
                    singleLine = false,
                )

                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(text = "Estimated Time", color = EmBeColors.MutedText, fontSize = 12.sp)
                    Text(
                        text = estimatedLabel.ifEmpty { "Select estimated time" },
                        color = if (estimatedLabel.isEmpty()) EmBeColors.MutedText else EmBeColors.DarkText,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, SoftBorder, RoundedCornerShape(10.dp))
                            .clickable { showTimePicker = true }
                            .padding(12.dp),
                    )
                }

                if (showValidation) {
                    Text(
                        text = "Enter a sub-task name to continue",
                        color = EmBeColors.ErrorCoral,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }
    }

    if (showTimePicker) {
        EstimatedTimePickerSheet(
            selectedLabel = estimatedLabel,
            onSelect = {
                estimatedLabel = it
                showTimePicker = false
            },
            onDismiss = { showTimePicker = false },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EstimatedTimePickerSheet(
    selectedLabel: String,
    onSelect: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
    ) {
        Column(modifier = Modifier.padding(bottom = 24.dp)) {
            Text(
                text = "Estimated Time",
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp),
            )
            BookingChecklistTask.estimateOptions.forEach { label ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onSelect(label) }
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(text = label, color = EmBeColors.DarkText, fontSize = 16.sp)
                    if (selectedLabel == label) {
                        Text(text = "✓", color = EmBeColors.LinkBlue, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
internal fun ComposerField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    singleLine: Boolean = true,
) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(text = label, color = EmBeColors.MutedText, fontSize = 12.sp)
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = { Text(placeholder, color = EmBeColors.MutedText) },
            singleLine = singleLine,
            minLines = if (singleLine) 1 else 3,
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
