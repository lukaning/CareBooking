package com.embelife.app.ui.settings

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
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.ListAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Wallet
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.GiftExperienceRoute
import com.embelife.app.ui.gift.GiftExperienceHost
import com.embelife.app.ui.profile.ProfileScreen
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

private val RowColor = Color(0xFF6F7680)
private val BadgeFill = Color(0xFFCABDEF)
private val SectionFill = Color(0xFFF7F8FB)

enum class SettingsDestination(
    val title: String,
    val icon: ImageVector,
    val badgeCount: Int? = null,
) {
    Profile("Profile", Icons.Filled.Person),
    Dashboard("Dashboard", Icons.Filled.GridView),
    UserManagement("User management", Icons.Filled.People),
    PasswordSecurity("Password & Security", Icons.Filled.Lock),
    Activities("Activities", Icons.AutoMirrored.Filled.ListAlt),
    GiftFund("Gift Fund", Icons.Filled.Wallet),
    Help("Help & getting started", Icons.Filled.HelpOutline, badgeCount = 1),
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var searchText by remember { mutableStateOf("") }
    var destination by remember { mutableStateOf<SettingsDestination?>(null) }
    var preferredLanguage by remember { mutableStateOf(appViewModel.preferredLanguage) }
    var showGiftFund by remember { mutableStateOf(false) }
    val languages = listOf("English", "Spanish", "Mandarin", "Cantonese", "French", "ASL")

    val filtered = SettingsDestination.entries.filter {
        searchText.isBlank() || it.title.contains(searchText, ignoreCase = true)
    }
    val showPreferences = searchText.isBlank() ||
        "language".contains(searchText, true) ||
        "text".contains(searchText, true) ||
        preferredLanguage.contains(searchText, true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        Icons.Filled.Close,
                        contentDescription = "Close",
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFE8E9ED))
                            .clickable(onClick = onDismiss)
                            .padding(6.dp),
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text("Settings", fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                    Spacer(modifier = Modifier.weight(1f))
                    Spacer(modifier = Modifier.size(36.dp))
                }

                OutlinedTextField(
                    value = searchText,
                    onValueChange = { searchText = it },
                    leadingIcon = { Icon(Icons.Filled.Search, null) },
                    placeholder = { Text("Search settings") },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                        .padding(bottom = 8.dp),
                    shape = RoundedCornerShape(12.dp),
                )

                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 20.dp)
                        .padding(bottom = 32.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    filtered.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable {
                                    when (item) {
                                        SettingsDestination.GiftFund -> showGiftFund = true
                                        SettingsDestination.Help -> Unit
                                        else -> destination = item
                                    }
                                }
                                .padding(vertical = 14.dp, horizontal = 4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                        ) {
                            Icon(item.icon, null, tint = RowColor, modifier = Modifier.size(22.dp))
                            Text(item.title, color = EmBeColors.DarkText, fontSize = 16.sp, modifier = Modifier.weight(1f))
                            item.badgeCount?.let {
                                Text(
                                    "$it",
                                    color = Color(0xFF1A1D1F),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier
                                        .clip(CircleShape)
                                        .background(BadgeFill)
                                        .padding(horizontal = 8.dp, vertical = 3.dp),
                                )
                            }
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = EmBeColors.MutedText)
                        }
                    }

                    if (showPreferences) {
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))
                        Text("Display & Language", color = EmBeColors.MutedText, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(14.dp))
                                .background(SectionFill)
                                .padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Text("Language Setting", color = EmBeColors.DarkText, fontWeight = FontWeight.SemiBold)
                            languages.chunked(3).forEach { row ->
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    row.forEach { lang ->
                                        val selected = preferredLanguage == lang
                                        Text(
                                            lang,
                                            color = if (selected) Color.White else EmBeColors.DarkText,
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            modifier = Modifier
                                                .clip(RoundedCornerShape(8.dp))
                                                .background(if (selected) EmBeColors.BrandOrange else Color.White)
                                                .clickable {
                                                    preferredLanguage = lang
                                                    appViewModel.preferredLanguage = lang
                                                }
                                                .padding(horizontal = 10.dp, vertical = 8.dp),
                                        )
                                    }
                                }
                            }
                            Text("Text Size", color = EmBeColors.DarkText, fontWeight = FontWeight.SemiBold)
                            Text("Managed in system accessibility settings", color = EmBeColors.MutedText, fontSize = 13.sp)
                        }
                    }
                }
            }

            when (destination) {
                SettingsDestination.Profile -> ProfileScreen(
                    appViewModel = appViewModel,
                    onDismiss = { destination = null },
                )
                SettingsDestination.Dashboard -> DashboardScreen(
                    appViewModel = appViewModel,
                    onBack = { destination = null },
                )
                SettingsDestination.UserManagement -> UserManagementScreen(
                    appViewModel = appViewModel,
                    onBack = { destination = null },
                )
                SettingsDestination.PasswordSecurity -> PasswordSecurityScreen(
                    onBack = { destination = null },
                )
                SettingsDestination.Activities -> ActivitiesScreen(
                    onBack = { destination = null },
                )
                else -> Unit
            }
        }
    }

    if (showGiftFund) {
        GiftExperienceHost(
            initialRoute = GiftExperienceRoute.Confirm,
            onDismiss = { showGiftFund = false },
        )
    }
}
