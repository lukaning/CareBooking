package com.embelife.app.ui.main

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Sms
import androidx.compose.material.icons.filled.Work
import androidx.compose.material.icons.outlined.Bookmark
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Sms
import androidx.compose.material.icons.outlined.Work
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.ui.booking.BookingsScreen
import com.embelife.app.ui.home.HomeScreen
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

/**
 * Port of `AppTab`. SF Symbols map onto the nearest Material equivalents; `bookmark`
 * and `briefcase` line up directly, `message` becomes `Sms` since Material's plain
 * `Message` glyph reads differently at tab-bar size.
 */
enum class AppTab(
    val title: String,
    val outlineIcon: ImageVector,
    val filledIcon: ImageVector,
) {
    Home("Home", Icons.Outlined.Home, Icons.Filled.Home),
    Messages("Messages", Icons.Outlined.Sms, Icons.Filled.Sms),
    Notes("Hands-free", Icons.Outlined.Bookmark, Icons.Filled.Bookmark),
    Notification("Notification", Icons.Outlined.Notifications, Icons.Filled.Notifications),
    Payment("Payment", Icons.Outlined.Work, Icons.Filled.Work),
}

private val InactiveTabColor = Color(0xFF9CA3AF)

@Composable
fun MainTabScreen(appViewModel: AppViewModel) {
    var selectedTab by remember { mutableStateOf(AppTab.Home) }

    Scaffold(
        containerColor = Color.White,
        bottomBar = {
            NavigationBar(containerColor = Color.White, tonalElevation = 0.dp) {
                AppTab.entries.forEach { tab ->
                    val isSelected = selectedTab == tab
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = { selectedTab = tab },
                        icon = {
                            Icon(
                                imageVector = if (isSelected) tab.filledIcon else tab.outlineIcon,
                                contentDescription = tab.title,
                            )
                        },
                        label = {
                            Text(
                                text = tab.title,
                                fontSize = 10.sp,
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = EmBeColors.BrandOrange,
                            selectedTextColor = EmBeColors.BrandOrange,
                            unselectedIconColor = InactiveTabColor,
                            unselectedTextColor = InactiveTabColor,
                            indicatorColor = Color.Transparent,
                        ),
                    )
                }
            }
        },
    ) { innerPadding ->
        when (selectedTab) {
            AppTab.Home -> HomeScreen(
                appViewModel = appViewModel,
                contentPadding = innerPadding,
            )

            AppTab.Notes -> BookingsScreen(
                appViewModel = appViewModel,
                contentPadding = innerPadding,
            )

            AppTab.Messages -> PlaceholderTab(
                title = "Messages",
                modifier = Modifier.padding(innerPadding),
            )

            AppTab.Notification -> PlaceholderTab(
                title = "Notification",
                modifier = Modifier.padding(innerPadding),
            )

            AppTab.Payment -> PlaceholderTab(
                title = "Payment",
                modifier = Modifier.padding(innerPadding),
            )
        }
    }
}

@Composable
private fun PlaceholderTab(title: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = title, color = EmBeColors.DarkText, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text(text = "Not ported yet", color = EmBeColors.Grayscale70, fontSize = 15.sp)
    }
}
