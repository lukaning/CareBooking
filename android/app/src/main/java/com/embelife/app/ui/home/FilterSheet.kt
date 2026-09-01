package com.embelife.app.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.ui.theme.EmBeColors
import kotlin.math.roundToInt

/**
 * Port of `FilterSheet`. The iOS version is a `Form` inside a sheet with Close/Apply
 * toolbar buttons; a `ModalBottomSheet` with the same header is the Compose equivalent.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterSheet(
    criterion: HomeFilterCriterion,
    state: HomeFilterState,
    onApply: (HomeFilterState) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    var draft by remember { mutableStateOf(state) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
    ) {
        Column(modifier = Modifier.navigationBarsPadding()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = "Close",
                    tint = EmBeColors.DarkText,
                    modifier = Modifier
                        .size(24.dp)
                        .clickable(onClick = onDismiss),
                )

                Spacer(modifier = Modifier.weight(1f))

                Text(
                    text = criterion.label,
                    color = EmBeColors.DarkText,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                )

                Spacer(modifier = Modifier.weight(1f))

                Text(
                    text = "Apply",
                    color = EmBeColors.BrandOrange,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clickable {
                        // iOS restores a default when the multi-selects are emptied.
                        onApply(
                            draft.copy(
                                ageRanges = draft.ageRanges.ifEmpty { listOf("25-30") },
                                languages = draft.languages.ifEmpty { listOf("English") },
                            ),
                        )
                    },
                )
            }

            HorizontalDivider(color = EmBeColors.CardBorder)

            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 12.dp),
            ) {
                when (criterion) {
                    HomeFilterCriterion.Location -> SingleChoiceSection(
                        title = "Location",
                        options = FilterOptions.location,
                        selected = draft.location,
                        onSelect = { draft = draft.copy(location = it) },
                    )

                    HomeFilterCriterion.TypeOfHelp -> SingleChoiceSection(
                        title = "Type of Help",
                        options = FilterOptions.typeOfHelp,
                        selected = draft.typeOfHelp,
                        onSelect = { draft = draft.copy(typeOfHelp = it) },
                    )

                    HomeFilterCriterion.ForWho -> {
                        SingleChoiceSection(
                            title = "Recipient",
                            options = FilterOptions.forWho,
                            selected = draft.forWho,
                            onSelect = { draft = draft.copy(forWho = it) },
                        )
                        SingleChoiceSection(
                            title = "Age group",
                            options = FilterOptions.careAgeGroup,
                            selected = draft.careRecipientAgeGroup,
                            onSelect = { draft = draft.copy(careRecipientAgeGroup = it) },
                        )
                    }

                    HomeFilterCriterion.AgeRange -> MultiChoiceSection(
                        title = "Provider age range",
                        options = FilterOptions.ageRange,
                        selected = draft.ageRanges,
                        onToggle = { option ->
                            draft = draft.copy(
                                ageRanges = draft.ageRanges.toggleSorted(
                                    option,
                                    FilterOptions.ageRange,
                                ),
                            )
                        },
                    )

                    HomeFilterCriterion.GenderIdentity -> SingleChoiceSection(
                        title = "Gender Identity",
                        options = FilterOptions.gender,
                        selected = draft.genderIdentity,
                        onSelect = { draft = draft.copy(genderIdentity = it) },
                    )

                    HomeFilterCriterion.Language -> {
                        MultiChoiceSection(
                            title = "Languages",
                            options = FilterOptions.language,
                            selected = draft.languages,
                            onToggle = { option ->
                                draft = draft.copy(
                                    languages = draft.languages.toggleSorted(
                                        option,
                                        FilterOptions.language,
                                    ),
                                )
                            },
                        )
                        Text(
                            text = "Select one or more languages. Currently selected: " +
                                draft.languages.ifEmpty { listOf("none") }.joinToString(", ") + ".",
                            color = EmBeColors.Grayscale70,
                            fontSize = 13.sp,
                            modifier = Modifier.padding(top = 8.dp),
                        )
                    }

                    HomeFilterCriterion.PriceRange -> PriceRangeSection(
                        minPrice = draft.minPrice,
                        maxPrice = draft.maxPrice,
                        onChange = { min, max ->
                            draft = draft.copy(minPrice = min, maxPrice = max)
                        },
                    )

                    HomeFilterCriterion.SpecialNeed -> SingleChoiceSection(
                        title = "Special need",
                        options = FilterOptions.specialNeed,
                        selected = draft.specialNeed,
                        onSelect = { draft = draft.copy(specialNeed = it) },
                    )
                }
            }
        }
    }
}

@Composable
private fun SingleChoiceSection(
    title: String,
    options: List<String>,
    selected: String,
    onSelect: (String) -> Unit,
) {
    SectionHeader(title)
    options.forEach { option ->
        ChoiceRow(
            label = option,
            isSelected = option == selected,
            onClick = { onSelect(option) },
        )
    }
}

@Composable
private fun MultiChoiceSection(
    title: String,
    options: List<String>,
    selected: List<String>,
    onToggle: (String) -> Unit,
) {
    SectionHeader(title)
    options.forEach { option ->
        ChoiceRow(
            label = option,
            isSelected = selected.contains(option),
            onClick = { onToggle(option) },
        )
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title.uppercase(),
        color = EmBeColors.Grayscale70,
        fontSize = 12.sp,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(top = 12.dp, bottom = 6.dp),
    )
}

@Composable
private fun ChoiceRow(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = label, color = EmBeColors.DarkText, fontSize = 17.sp)
        Spacer(modifier = Modifier.weight(1f))
        if (isSelected) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = EmBeColors.BrandOrange,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

@Composable
private fun PriceRangeSection(
    minPrice: Float,
    maxPrice: Float,
    onChange: (Float, Float) -> Unit,
) {
    SectionHeader("Hourly rate")

    DualRangeSlider(
        minValue = minPrice,
        maxValue = maxPrice,
        bounds = FilterOptions.priceBounds,
        onValueChange = onChange,
        modifier = Modifier.padding(vertical = 8.dp),
    )

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        PriceNumberField(
            title = "Min (\$/hr)",
            value = minPrice,
            modifier = Modifier.weight(1f),
        ) { entered ->
            onChange(entered.coerceIn(FilterOptions.priceBounds.start, maxPrice), maxPrice)
        }
        PriceNumberField(
            title = "Max (\$/hr)",
            value = maxPrice,
            modifier = Modifier.weight(1f),
        ) { entered ->
            onChange(minPrice, entered.coerceIn(minPrice, FilterOptions.priceBounds.endInclusive))
        }
    }

    Text(
        text = "Showing $${minPrice.roundToInt()} – $${maxPrice.roundToInt()}/hour",
        color = EmBeColors.BrandOrange,
        fontSize = 15.sp,
        fontWeight = FontWeight.Medium,
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 10.dp),
    )

    Text(
        text = "Drag either handle to set a range, or type an exact min and max rate.",
        color = EmBeColors.Grayscale70,
        fontSize = 13.sp,
        modifier = Modifier.padding(top = 6.dp),
    )
}

@Composable
private fun PriceNumberField(
    title: String,
    value: Float,
    modifier: Modifier = Modifier,
    onCommit: (Float) -> Unit,
) {
    var text by remember(value) { mutableStateOf(value.roundToInt().toString()) }

    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = title,
            color = EmBeColors.MutedText,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
        )

        OutlinedTextField(
            value = text,
            onValueChange = { raw ->
                text = raw.filter { it.isDigit() }
                text.toFloatOrNull()?.let(onCommit)
            },
            prefix = { Text(text = "$", fontWeight = FontWeight.SemiBold) },
            singleLine = true,
            shape = RoundedCornerShape(10.dp),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Done,
            ),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

/** Keeps multi-select order aligned with the option list, matching the iOS sort. */
private fun List<String>.toggleSorted(option: String, order: List<String>): List<String> =
    if (contains(option)) {
        this - option
    } else {
        (this + option).sortedBy { order.indexOf(it) }
    }
