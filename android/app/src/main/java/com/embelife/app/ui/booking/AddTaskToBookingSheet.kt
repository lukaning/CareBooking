package com.embelife.app.ui.booking

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
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
import com.embelife.app.model.BookingTaskCatalog
import com.embelife.app.model.BookingTaskOption
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import java.util.UUID

private val SoftBorder = Color(0xFFE6E8EE)
private val SelectedChipFill = Color(0xFFE0EDFF)
private val PageBG = Color(0xFFF5F5F7)
private val SuggestedFill = Color(0xFFEBE6F7)
private val CheckGreen = Color(0xFF33B366)

private enum class AddTaskScreen { AddTask, Suggested, AddSubtask }

/**
 * Port of `AddTaskToBookingSheet` — append / edit a care task on a Requested or Booked visit.
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AddTaskToBookingSheet(
    bookingID: UUID,
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
    parentTaskID: UUID? = null,
    editingTask: BookingChecklistTask? = null,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var screen by remember {
        mutableStateOf(if (parentTaskID == null) AddTaskScreen.AddTask else AddTaskScreen.AddSubtask)
    }

    val matchedOption = editingTask?.let { task ->
        BookingTaskCatalog.allOptions.firstOrNull {
            it.title == task.subcategory || it.title == task.title
        }
    }

    var selectedCategoryID by remember { mutableStateOf(matchedOption?.id) }
    var descriptionText by remember {
        mutableStateOf(
            editingTask?.let {
                if (it.detailDescription.isEmpty()) it.title else it.detailDescription
            }.orEmpty(),
        )
    }
    var estimatedLabel by remember {
        mutableStateOf(
            editingTask?.estimatedMinutes?.let { BookingChecklistTask.estimateLabel(it) }.orEmpty(),
        )
    }
    var subtasks by remember { mutableStateOf(editingTask?.subtasks.orEmpty()) }
    var selectedSuggestedIDs by remember { mutableStateOf(setOf<UUID>()) }
    var workingSuggestedTasks by remember { mutableStateOf(emptyList<BookingChecklistTask>()) }
    var selectedCategoryIDs by remember { mutableStateOf(setOf<String>()) }
    var showTimePicker by remember { mutableStateOf(false) }
    var showCategoryPicker by remember { mutableStateOf(false) }
    var showValidation by remember { mutableStateOf(false) }

    val selectedCategoryOption = BookingTaskCatalog.allOptions.firstOrNull { it.id == selectedCategoryID }
    val canSaveTask = descriptionText.trim().isNotEmpty() ||
        selectedCategoryOption != null ||
        subtasks.isNotEmpty()

    fun rebuildSuggestedTasks(selectAllIfEmpty: Boolean) {
        val options = BookingTaskCatalog.allOptions.filter { selectedCategoryIDs.contains(it.id) }
        val previouslyChecked = workingSuggestedTasks
            .filter { selectedSuggestedIDs.contains(it.id) }
            .map { it.title }
            .toSet()
        workingSuggestedTasks = BookingTaskCatalog.suggestedChecklist(options)
        selectedSuggestedIDs = if (previouslyChecked.isEmpty() && selectAllIfEmpty) {
            workingSuggestedTasks.map { it.id }.toSet()
        } else {
            workingSuggestedTasks.filter { previouslyChecked.contains(it.title) }.map { it.id }.toSet()
        }
    }

    fun makeParentTask(id: UUID? = null): BookingChecklistTask? {
        val option = selectedCategoryOption
        val trimmed = descriptionText.trim()
        val title = trimmed.ifEmpty { option?.title ?: subtasks.firstOrNull()?.title } ?: return null
        if (title.isEmpty()) return null
        return BookingChecklistTask(
            id = id ?: UUID.randomUUID(),
            title = title,
            category = option?.categoryTitle ?: editingTask?.category ?: "Custom task",
            subcategory = option?.title ?: editingTask?.subcategory ?: title,
            priority = editingTask?.priority ?: com.embelife.app.model.BookingTaskPriority.Medium,
            deadline = editingTask?.deadline,
            detailDescription = trimmed,
            estimatedMinutes = BookingChecklistTask.minutesFromEstimateLabel(estimatedLabel),
            attachmentNames = editingTask?.attachmentNames.orEmpty(),
            subtasks = subtasks,
        )
    }

    fun save() {
        val parentID = parentTaskID
        if (parentID != null) {
            // Subtask-only path is handled by AddSubTask screen.
            return
        }
        val task = makeParentTask(id = editingTask?.id)
        if (task == null) {
            showValidation = true
            return
        }
        if (editingTask != null) {
            appViewModel.replaceChecklistTask(bookingID, task)
        } else {
            appViewModel.appendChecklistTasks(bookingID, listOf(task))
        }
        onDismiss()
    }

    fun applySuggestedSelection() {
        val catalogChosen = workingSuggestedTasks.filter { selectedSuggestedIDs.contains(it.id) }
        val savedChosen = appViewModel.savedTaskTemplates.filter { selectedSuggestedIDs.contains(it.id) }
        val chosen = catalogChosen + savedChosen
        chosen.firstOrNull()?.let { first ->
            selectedCategoryID = BookingTaskCatalog.allOptions.firstOrNull {
                it.title == first.title && it.categoryTitle == first.category
            }?.id ?: selectedCategoryID
            if (descriptionText.trim().isEmpty()) descriptionText = first.title
            chosen.drop(1).forEach { item ->
                if (subtasks.none { it.title == item.title }) {
                    subtasks = subtasks + BookingChecklistTask(
                        title = item.title,
                        category = item.category,
                        subcategory = item.subcategory,
                        detailDescription = item.detailDescription,
                    )
                }
            }
        }
        screen = AddTaskScreen.AddTask
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = PageBG,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding(),
        ) {
            when (screen) {
                AddTaskScreen.AddTask -> Column {
                    AddTaskNavHeader(
                        title = if (editingTask == null) "Add Task" else "Edit Task",
                        doneEnabled = canSaveTask,
                        onBack = onDismiss,
                        onDone = { save() },
                    )
                    Column(
                        modifier = Modifier
                            .verticalScroll(rememberScrollState())
                            .padding(horizontal = 16.dp)
                            .padding(bottom = 28.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(SuggestedFill)
                                .clickable {
                                    rebuildSuggestedTasks(selectAllIfEmpty = workingSuggestedTasks.isEmpty())
                                    screen = AddTaskScreen.Suggested
                                }
                                .padding(14.dp),
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = Color(0xFF7366BF))
                            Text(
                                "Suggested Tasks Checklist",
                                color = EmBeColors.DarkText,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.weight(1f),
                            )
                            Icon(
                                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                contentDescription = null,
                                tint = EmBeColors.MutedText,
                            )
                        }

                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(16.dp))
                                .background(Color.White)
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp),
                        ) {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Filled.Checklist, contentDescription = null, tint = EmBeColors.MutedText)
                                Text("Task Details", color = EmBeColors.MutedText, fontSize = 14.sp)
                            }

                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("Task Category", color = EmBeColors.MutedText, fontSize = 12.sp)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .border(1.dp, SoftBorder, RoundedCornerShape(10.dp))
                                        .clickable { showCategoryPicker = true }
                                        .padding(12.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Text(
                                        text = selectedCategoryOption?.title
                                            ?: "Select one of the following category",
                                        color = if (selectedCategoryOption == null) {
                                            EmBeColors.MutedText
                                        } else {
                                            EmBeColors.DarkText
                                        },
                                        fontSize = 14.sp,
                                        fontWeight = if (selectedCategoryOption == null) {
                                            FontWeight.Normal
                                        } else {
                                            FontWeight.SemiBold
                                        },
                                        modifier = Modifier.weight(1f),
                                    )
                                    Icon(Icons.Filled.ExpandMore, contentDescription = null, tint = EmBeColors.MutedText)
                                }
                            }

                            ComposerField(
                                label = "Description",
                                value = descriptionText,
                                onValueChange = {
                                    descriptionText = it
                                    showValidation = false
                                },
                                placeholder = "Describe the support needed…",
                                singleLine = false,
                            )

                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("Estimated Time", color = EmBeColors.MutedText, fontSize = 12.sp)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .border(1.dp, SoftBorder, RoundedCornerShape(10.dp))
                                        .clickable { showTimePicker = true }
                                        .padding(12.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                ) {
                                    Text(
                                        text = estimatedLabel.ifEmpty { " " },
                                        color = EmBeColors.DarkText,
                                        fontWeight = FontWeight.SemiBold,
                                    )
                                    Icon(
                                        Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                        contentDescription = null,
                                        tint = EmBeColors.MutedText,
                                    )
                                }
                            }
                        }

                        SubtaskListSection(
                            subtasks = subtasks,
                            onAdd = { screen = AddTaskScreen.AddSubtask },
                        )

                        if (showValidation) {
                            Text(
                                "Add a category, description, or sub-task before tapping Done",
                                color = EmBeColors.ErrorCoral,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                        }
                    }
                }

                AddTaskScreen.Suggested -> Column {
                    AddTaskNavHeader(
                        title = "Add Task",
                        doneEnabled = true,
                        onBack = { screen = AddTaskScreen.AddTask },
                        onDone = { applySuggestedSelection() },
                    )
                    Column(
                        modifier = Modifier
                            .verticalScroll(rememberScrollState())
                            .padding(horizontal = 16.dp)
                            .padding(bottom = 28.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                    ) {
                        BookingTaskCatalog.groups.forEach { group ->
                            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text(group.title, color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                FlowRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalArrangement = Arrangement.spacedBy(8.dp),
                                ) {
                                    group.options.forEach { option ->
                                        SuggestedCategoryChip(
                                            option = option,
                                            selected = selectedCategoryIDs.contains(option.id),
                                            onToggle = {
                                                selectedCategoryIDs = if (selectedCategoryIDs.contains(option.id)) {
                                                    selectedCategoryIDs - option.id
                                                } else {
                                                    selectedCategoryIDs + option.id
                                                }
                                                rebuildSuggestedTasks(selectAllIfEmpty = true)
                                            },
                                        )
                                    }
                                }
                            }
                        }

                        workingSuggestedTasks.forEach { task ->
                            val selected = selectedSuggestedIDs.contains(task.id)
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(Color.White)
                                    .clickable {
                                        selectedSuggestedIDs = if (selected) {
                                            selectedSuggestedIDs - task.id
                                        } else {
                                            selectedSuggestedIDs + task.id
                                        }
                                    }
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                            ) {
                                Icon(
                                    if (selected) Icons.Filled.CheckBox else Icons.Filled.CheckBoxOutlineBlank,
                                    contentDescription = null,
                                    tint = if (selected) CheckGreen else EmBeColors.LinkBlue.copy(alpha = 0.55f),
                                )
                                Column {
                                    Text(task.title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                    Text(task.category, color = EmBeColors.MutedText, fontSize = 12.sp)
                                }
                            }
                        }

                        appViewModel.savedTaskTemplates.forEach { task ->
                            val selected = selectedSuggestedIDs.contains(task.id)
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(Color.White)
                                    .clickable {
                                        selectedSuggestedIDs = if (selected) {
                                            selectedSuggestedIDs - task.id
                                        } else {
                                            selectedSuggestedIDs + task.id
                                        }
                                    }
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                            ) {
                                Icon(
                                    if (selected) Icons.Filled.CheckBox else Icons.Filled.CheckBoxOutlineBlank,
                                    contentDescription = null,
                                    tint = if (selected) CheckGreen else EmBeColors.LinkBlue.copy(alpha = 0.55f),
                                )
                                Column {
                                    Text(task.title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                    Text("Saved · ${task.category}", color = EmBeColors.MutedText, fontSize = 12.sp)
                                }
                            }
                        }
                    }
                }

                AddTaskScreen.AddSubtask -> {
                    // Nested sheet handles its own chrome; keep parent visible underneath.
                }
            }
        }
    }

    if (screen == AddTaskScreen.AddSubtask) {
        AddSubTaskComposerSheet(
            onCancel = {
                if (parentTaskID != null) onDismiss() else screen = AddTaskScreen.AddTask
            },
            onSave = { task ->
                if (parentTaskID != null) {
                    appViewModel.appendSubtask(bookingID, parentTaskID, task)
                    onDismiss()
                } else {
                    subtasks = subtasks + task
                    screen = AddTaskScreen.AddTask
                }
            },
        )
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

    if (showCategoryPicker) {
        CategoryPickerSheet(
            selectedCategoryID = selectedCategoryID,
            onSelect = { option ->
                selectedCategoryID = option.id
                if (descriptionText.trim().isEmpty()) descriptionText = option.title
                showCategoryPicker = false
            },
            onDismiss = { showCategoryPicker = false },
        )
    }
}

@Composable
private fun SuggestedCategoryChip(
    option: BookingTaskOption,
    selected: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (selected) SelectedChipFill else Color.White)
            .border(
                1.dp,
                if (selected) EmBeColors.LinkBlue.copy(alpha = 0.45f) else SoftBorder,
                RoundedCornerShape(12.dp),
            )
            .clickable(onClick = onToggle)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (selected) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = EmBeColors.LinkBlue, modifier = Modifier.padding(0.dp))
        }
        Text(
            option.title,
            color = if (selected) Color(0xFF26408C) else EmBeColors.DarkText,
            fontSize = 14.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CategoryPickerSheet(
    selectedCategoryID: String?,
    onSelect: (BookingTaskOption) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
    ) {
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(bottom = 24.dp),
        ) {
            Text(
                "Task Category",
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
            )
            BookingTaskCatalog.groups.forEach { group ->
                Text(
                    group.title,
                    color = EmBeColors.MutedText,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
                )
                group.options.forEach { option ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(option) }
                            .padding(horizontal = 20.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text(option.title, color = EmBeColors.DarkText, fontSize = 15.sp)
                        if (selectedCategoryID == option.id) {
                            Text("✓", color = EmBeColors.LinkBlue, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
            Spacer(modifier = Modifier.padding(8.dp))
        }
    }
}
