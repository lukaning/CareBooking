package com.embelife.app.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Tune
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.embelife.app.model.BookingStatus
import com.embelife.app.model.Provider
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

private val PageBackground = Color(0xFFF2F2F7)
private val ChipBorder = Color(0xFFE6E8EE)
private val ChipValueColor = Color(0xFF737F94)
private val MenuHighlight = Color(0xFFF0F2F5)
private val MenuInactiveText = Color(0xFF73798C)

/** Port of `HomeView`. */
@Composable
fun HomeScreen(
    appViewModel: AppViewModel,
    contentPadding: PaddingValues,
) {
    var filtersExpanded by remember { mutableStateOf(false) }
    var activeFilter by remember { mutableStateOf<HomeFilterCriterion?>(null) }
    var filterState by remember { mutableStateOf(HomeFilterState()) }
    var bookingMenuProviderID by remember { mutableStateOf<String?>(null) }
    var listMode by remember { mutableStateOf(HomeProviderListMode.YourMatches) }
    var showListMenu by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { appViewModel.seedBookingsIfNeeded() }

    val providers: List<Provider> = when (listMode) {
        HomeProviderListMode.YourMatches -> appViewModel.providers

        // Demo: first and last as "saved".
        HomeProviderListMode.SavedProviders -> appViewModel.providers.let { all ->
            if (all.size > 1) listOf(all.first(), all.last()) else all
        }

        HomeProviderListMode.PreviousProviders -> {
            val ids = appViewModel.bookings
                .filter { it.status == BookingStatus.Completed }
                .map { it.provider.id }
                .toSet()
            appViewModel.providers.filter { ids.contains(it.id) }
                .ifEmpty { appViewModel.providers.take(1) }
        }
    }

    val bookedCount = appViewModel.bookings.count { it.status == BookingStatus.Booked }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageBackground)
            .padding(bottom = contentPadding.calculateBottomPadding()),
    ) {
        HomeTopBar(bookedCount = bookedCount)

        MatchesHeader(
            listMode = listMode,
            showListMenu = showListMenu,
            onToggleListMenu = {
                filtersExpanded = false
                showListMenu = !showListMenu
            },
            onSelectListMode = {
                listMode = it
                showListMenu = false
            },
            filtersExpanded = filtersExpanded,
            onToggleFilters = {
                showListMenu = false
                filtersExpanded = !filtersExpanded
            },
            filterState = filterState,
            onSelectCriterion = { activeFilter = it },
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            items(providers, key = { it.id }) { provider ->
                ProviderCard(
                    provider = provider,
                    isBookingMenuExpanded = bookingMenuProviderID == provider.id,
                    onToggleBookingMenu = {
                        bookingMenuProviderID =
                            if (bookingMenuProviderID == provider.id) null else provider.id
                    },
                    onSelectAppointmentType = {
                        bookingMenuProviderID = null
                        // Booking sheet is wired up with the Booking module.
                    },
                    onRatingTap = { },
                )
            }
        }
    }

    activeFilter?.let { criterion ->
        FilterSheet(
            criterion = criterion,
            state = filterState,
            onApply = {
                filterState = it
                activeFilter = null
            },
            onDismiss = { activeFilter = null },
        )
    }
}

@Composable
private fun HomeTopBar(bookedCount: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White)
            .statusBarsPadding()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.Menu,
            contentDescription = "Settings",
            tint = EmBeColors.DarkText,
        )

        Spacer(modifier = Modifier.weight(1f))

        Text(
            text = "Home",
            color = EmBeColors.DarkText,
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold,
        )

        Spacer(modifier = Modifier.weight(1f))

        Box(modifier = Modifier.size(width = 32.dp, height = 28.dp)) {
            Icon(
                imageVector = Icons.Filled.CalendarToday,
                contentDescription = "Booked",
                tint = EmBeColors.DarkText,
                modifier = Modifier.align(Alignment.Center),
            )
            if (bookedCount > 0) {
                Text(
                    text = if (bookedCount > 9) "9+" else "$bookedCount",
                    color = Color.White,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .clip(CircleShape)
                        .background(EmBeColors.BrandOrange)
                        .padding(horizontal = 4.dp, vertical = 1.dp),
                )
            }
        }
    }
}

@Composable
private fun MatchesHeader(
    listMode: HomeProviderListMode,
    showListMenu: Boolean,
    onToggleListMenu: () -> Unit,
    onSelectListMode: (HomeProviderListMode) -> Unit,
    filtersExpanded: Boolean,
    onToggleFilters: () -> Unit,
    filterState: HomeFilterState,
    onSelectCriterion: (HomeFilterCriterion) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White)
            .zIndex(if (showListMenu) 4f else 0f),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(top = 12.dp, bottom = if (filtersExpanded) 10.dp else 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(modifier = Modifier.zIndex(2f)) {
                Row(
                    modifier = Modifier.clickable(onClick = onToggleListMenu),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = listMode.title,
                        color = EmBeColors.DarkText,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Icon(
                        imageVector = Icons.Filled.ExpandMore,
                        contentDescription = null,
                        tint = EmBeColors.DarkText,
                        modifier = Modifier.size(18.dp),
                    )
                }

                if (showListMenu) {
                    Box(modifier = Modifier.padding(top = 36.dp)) {
                        ListModeMenu(selected = listMode, onSelect = onSelectListMode)
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(
                        if (filtersExpanded) {
                            EmBeColors.BrandOrange.copy(alpha = 0.12f)
                        } else {
                            Color.Transparent
                        },
                    )
                    .border(
                        1.dp,
                        if (filtersExpanded) {
                            EmBeColors.BrandOrange.copy(alpha = 0.45f)
                        } else {
                            Color(0xFFE0E0E6)
                        },
                        RoundedCornerShape(10.dp),
                    )
                    .clickable(onClick = onToggleFilters),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.Tune,
                    contentDescription = if (filtersExpanded) "Hide filters" else "Show filters",
                    tint = if (filtersExpanded) EmBeColors.BrandOrange else EmBeColors.DarkText,
                )
            }
        }

        if (filtersExpanded) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                HomeFilterCriterion.entries.forEach { criterion ->
                    FilterCriterionChip(
                        criterion = criterion,
                        summary = filterState.chipSummary(criterion),
                        onClick = { onSelectCriterion(criterion) },
                    )
                }
            }
        }
    }
}

@Composable
private fun ListModeMenu(
    selected: HomeProviderListMode,
    onSelect: (HomeProviderListMode) -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        shadowElevation = 8.dp,
        modifier = Modifier
            .width(188.dp)
            .border(1.dp, Color(0xFFE6E8EE), RoundedCornerShape(12.dp)),
    ) {
        Column(
            modifier = Modifier.padding(6.dp),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            HomeProviderListMode.entries.forEach { mode ->
                val isSelected = mode == selected
                Text(
                    text = mode.title,
                    color = if (isSelected) EmBeColors.DarkText else MenuInactiveText,
                    fontSize = 15.sp,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(if (isSelected) MenuHighlight else Color.Transparent)
                        .clickable { onSelect(mode) }
                        .padding(horizontal = 12.dp, vertical = 11.dp),
                )
            }
        }
    }
}

@Composable
private fun FilterCriterionChip(
    criterion: HomeFilterCriterion,
    summary: String,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Color.White)
            .border(1.dp, ChipBorder, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(
            imageVector = criterion.icon,
            contentDescription = null,
            tint = EmBeColors.DarkText,
            modifier = Modifier.size(18.dp),
        )
        Text(
            text = "${criterion.label}:",
            color = EmBeColors.DarkText,
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = summary,
            color = ChipValueColor,
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Icon(
            imageVector = Icons.Filled.ExpandMore,
            contentDescription = null,
            tint = EmBeColors.DarkText.copy(alpha = 0.75f),
            modifier = Modifier.size(14.dp),
        )
    }
}
