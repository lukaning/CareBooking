package com.embelife.app.ui.onboarding

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
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
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
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.OnboardingServiceCatalog
import com.embelife.app.model.ServiceCategory
import com.embelife.app.model.ServiceOptionGroup
import com.embelife.app.model.ServiceSubOption
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

private val ChipBorder = Color(0xFFEEEEEE)

/** Port of `ServiceNeedsStep`. */
@Composable
fun ServiceNeedsStep(
    appViewModel: AppViewModel,
    onContinue: () -> Unit,
) {
    var selectedCategoryID by remember { mutableStateOf<String?>(null) }

    val canContinue = run {
        val categoryID = selectedCategoryID ?: return@run false
        val leaves = appViewModel.selectedSubServiceIDs[categoryID].orEmpty()
        if (leaves.isEmpty()) return@run false
        // "Other (describe)" requires text.
        leaves.all { leafID ->
            val option = OnboardingServiceCatalog.option(leafID, categoryID) ?: return@all true
            if (!option.requiresDescription) return@all true
            appViewModel.serviceOptionNotes[leafID].orEmpty().isNotBlank()
        }
    }

    fun selectCategory(id: String) {
        if (selectedCategoryID == id) {
            selectedCategoryID = null
            appViewModel.selectedServiceIDs.clear()
            appViewModel.clearServiceSelections(id)
            return
        }
        selectedCategoryID?.let { appViewModel.clearServiceSelections(it) }
        selectedCategoryID = id
        appViewModel.selectedServiceIDs.clear()
        appViewModel.selectedServiceIDs.add(id)
        appViewModel.selectedSubServiceIDs.putIfAbsent(id, emptySet())
        appViewModel.selectedServiceGroupIDs.putIfAbsent(id, emptySet())
    }

    Column(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
        ) {
            Text(
                text = "What kind of help or support do you need?",
                color = EmBeColors.DarkText,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(top = 20.dp, bottom = 12.dp),
            )

            ServiceCategory.all.forEach { service ->
                ServiceCategoryRow(
                    service = service,
                    isSelected = selectedCategoryID == service.id,
                    appViewModel = appViewModel,
                    onSelect = { selectCategory(service.id) },
                )
            }
        }

        OnboardingBottomBar(title = "Next", enabled = canContinue, onClick = onContinue)
    }
}

@Composable
private fun ServiceCategoryRow(
    service: ServiceCategory,
    isSelected: Boolean,
    appViewModel: AppViewModel,
    onSelect: () -> Unit,
) {
    val groups = OnboardingServiceCatalog.optionGroups(service.id)
    val isNested = groups.isNotEmpty()

    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onSelect)
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            OnboardingRadioControl(isSelected = isSelected)

            ServiceCategoryIcon(service = service, isSelected = isSelected)

            Text(
                text = service.title,
                color = if (isSelected) EmBeColors.BrandOrange else EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth(),
            )
        }

        if (isSelected) {
            Box(
                modifier = Modifier
                    .padding(start = 40.dp)
                    .padding(top = 4.dp, bottom = 12.dp),
            ) {
                if (isNested) {
                    NestedOptions(
                        categoryID = service.id,
                        groups = groups,
                        appViewModel = appViewModel,
                    )
                } else {
                    FlatOptions(categoryID = service.id, appViewModel = appViewModel)
                }
            }
        }
    }
}

@Composable
private fun ServiceCategoryIcon(service: ServiceCategory, isSelected: Boolean) {
    val selectedRes = service.selectedImageRes
    if (selectedRes != null) {
        Image(
            painter = painterResource(if (isSelected) selectedRes else service.imageRes),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier.size(48.dp),
        )
    } else {
        // iOS renders these as template images tinted by selection state.
        Image(
            painter = painterResource(service.imageRes),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            colorFilter = ColorFilter.tint(
                if (isSelected) EmBeColors.BrandOrange else EmBeColors.DarkText,
            ),
            modifier = Modifier.size(48.dp),
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FlatOptions(categoryID: String, appViewModel: AppViewModel) {
    val options = OnboardingServiceCatalog.subOptions(categoryID)
    val selected = appViewModel.selectedSubServiceIDs[categoryID].orEmpty()

    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        options.forEach { option ->
            SubServiceChip(
                option = option,
                isSelected = selected.contains(option.id),
                onClick = { toggleLeaf(appViewModel, categoryID, option) },
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun NestedOptions(
    categoryID: String,
    groups: List<ServiceOptionGroup>,
    appViewModel: AppViewModel,
) {
    val selectedGroups = appViewModel.selectedServiceGroupIDs[categoryID].orEmpty()
    val selectedLeaves = appViewModel.selectedSubServiceIDs[categoryID].orEmpty()

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        groups.forEach { group ->
            val groupSelected = selectedGroups.contains(group.id)

            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                GroupChip(
                    group = group,
                    isSelected = groupSelected,
                    onClick = { toggleGroup(appViewModel, categoryID, group, groupSelected) },
                )

                if (groupSelected) {
                    Column(
                        modifier = Modifier.padding(start = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            group.children.forEach { option ->
                                SubServiceChip(
                                    option = option,
                                    isSelected = selectedLeaves.contains(option.id),
                                    onClick = { toggleLeaf(appViewModel, categoryID, option) },
                                )
                            }
                        }

                        group.children
                            .filter {
                                selectedLeaves.contains(it.id) &&
                                    (it.allowsNotes || it.requiresDescription)
                            }
                            .forEach { option ->
                                NotesField(option = option, appViewModel = appViewModel)
                            }
                    }
                }
            }
        }
    }
}

@Composable
private fun GroupChip(
    group: ServiceOptionGroup,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (isSelected) EmBeColors.BrandOrange else Color.White)
            .border(
                1.dp,
                if (isSelected) EmBeColors.BrandOrange else ChipBorder,
                RoundedCornerShape(12.dp),
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = group.title,
            color = if (isSelected) Color.White else EmBeColors.DarkText,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.weight(1f))
        Icon(
            imageVector = if (isSelected) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
            contentDescription = null,
            tint = if (isSelected) Color.White.copy(alpha = 0.95f) else EmBeColors.Grayscale60,
            modifier = Modifier.size(18.dp),
        )
    }
}

@Composable
private fun SubServiceChip(
    option: ServiceSubOption,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (isSelected) EmBeColors.BrandOrange else Color.White)
            .border(
                1.dp,
                if (isSelected) EmBeColors.BrandOrange else ChipBorder,
                RoundedCornerShape(12.dp),
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = option.title,
            color = if (isSelected) Color.White else EmBeColors.DarkText,
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
        )
        if (isSelected) {
            Icon(
                imageVector = Icons.Filled.Cancel,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.95f),
                modifier = Modifier.size(16.dp),
            )
        }
    }
}

@Composable
private fun NotesField(option: ServiceSubOption, appViewModel: AppViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = if (option.requiresDescription) {
                "Describe: ${option.title}"
            } else {
                "Notes: ${option.title}"
            },
            color = EmBeColors.Grayscale70,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
        )

        OutlinedTextField(
            value = appViewModel.serviceOptionNotes[option.id].orEmpty(),
            onValueChange = { appViewModel.serviceOptionNotes[option.id] = it },
            placeholder = {
                Text(
                    text = if (option.requiresDescription) {
                        "Describe your needs…"
                    } else {
                        "Add specific instructions or notes…"
                    },
                    color = EmBeColors.Grayscale60,
                    fontSize = 15.sp,
                )
            },
            minLines = 2,
            maxLines = 4,
            shape = RoundedCornerShape(10.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White,
                focusedBorderColor = EmBeColors.BrandOrange,
                unfocusedBorderColor = Color.Black.copy(alpha = 0.12f),
            ),
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

private fun toggleLeaf(
    appViewModel: AppViewModel,
    categoryID: String,
    option: ServiceSubOption,
) {
    val current = appViewModel.selectedSubServiceIDs[categoryID].orEmpty()
    appViewModel.selectedSubServiceIDs[categoryID] = if (current.contains(option.id)) {
        appViewModel.serviceOptionNotes.remove(option.id)
        current - option.id
    } else {
        current + option.id
    }
}

private fun toggleGroup(
    appViewModel: AppViewModel,
    categoryID: String,
    group: ServiceOptionGroup,
    isSelected: Boolean,
) {
    val groups = appViewModel.selectedServiceGroupIDs[categoryID].orEmpty()
    var leaves = appViewModel.selectedSubServiceIDs[categoryID].orEmpty()

    if (isSelected) {
        group.children.forEach { child ->
            leaves = leaves - child.id
            appViewModel.serviceOptionNotes.remove(child.id)
        }
        appViewModel.selectedServiceGroupIDs[categoryID] = groups - group.id
    } else {
        appViewModel.selectedServiceGroupIDs[categoryID] = groups + group.id
    }
    appViewModel.selectedSubServiceIDs[categoryID] = leaves
}
