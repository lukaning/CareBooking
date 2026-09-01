package com.embelife.app.ui.notification

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.AppNotificationItem
import com.embelife.app.model.NotificationSection
import com.embelife.app.ui.theme.EmBeColors

private val TitleColor = Color(0xFF1F242E)
private val MetaColor = Color(0xFF8C949E)
private val TimeColor = Color(0xFFA6ADB8)
private val UnreadDot = Color(0xFF338CF2)
private val ReadDot = Color(0xFFE0E3E8)
private val BubbleBlue = Color(0xFF338CF2)
private val AcceptGreen = Color(0xFF2EB873)
private val DeclineRed = Color(0xFFEB5959)

@Composable
fun NotificationScreen(contentPadding: PaddingValues) {
    val items = AppNotificationItem.samples

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(bottom = contentPadding.calculateBottomPadding()),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Spacer(modifier = Modifier.width(32.dp))
            Text(
                text = "Notification",
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Icon(Icons.Filled.MoreHoriz, contentDescription = "More", tint = EmBeColors.DarkText)
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 24.dp),
        ) {
            NotificationSection.entries.forEach { section ->
                val sectionItems = items.filter { it.section == section }
                if (sectionItems.isEmpty()) return@forEach
                Text(
                    text = section.title,
                    color = TitleColor,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                )
                sectionItems.forEachIndexed { index, item ->
                    NotificationRow(item)
                    if (index < sectionItems.lastIndex) {
                        HorizontalDivider(modifier = Modifier.padding(start = 72.dp), color = Color(0xFFF0F1F4))
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationRow(item: AppNotificationItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(item.avatarColor),
            contentAlignment = Alignment.Center,
        ) {
            Text(item.initials, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 14.sp)
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    item.title,
                    color = TitleColor,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                )
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(if (item.isUnread) UnreadDot else ReadDot),
                    )
                    Text(item.timeLabel, color = TimeColor, fontSize = 10.sp)
                }
            }
            item.metaLine?.let { Text(it, color = MetaColor, fontSize = 12.sp) }
            item.taskDetail?.let {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.GridView, contentDescription = null, tint = MetaColor, modifier = Modifier.size(14.dp))
                    Text(it, color = MetaColor, fontSize = 12.sp)
                }
            }
            item.messageBubble?.let {
                Text(
                    it,
                    color = Color.White,
                    fontSize = 14.sp,
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(BubbleBlue)
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                )
            }
            if (item.attachmentCount > 0) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    repeat(item.attachmentCount) { index ->
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFFE6E8EE).copy(alpha = 1f - index * 0.05f)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Photo, contentDescription = null, tint = MetaColor)
                        }
                    }
                }
            }
            if (item.showsActions) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(top = 4.dp)) {
                    ActionChip("Accept", Icons.Filled.Check, AcceptGreen, Modifier.weight(1f))
                    ActionChip("Decline", Icons.Filled.Close, DeclineRed, Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun ActionChip(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .border(1.5.dp, color, RoundedCornerShape(10.dp))
            .clickable { }
            .padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(14.dp))
        Spacer(modifier = Modifier.width(6.dp))
        Text(title, color = color, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
    }
}
