package com.embelife.app.ui.settings

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.Devices
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.BookingStatus
import com.embelife.app.model.FeatureAccessKey
import com.embelife.app.model.ManagedTeamUser
import com.embelife.app.model.TeamAccessRole
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

private val PageBG = Color(0xFFF7F7FA)
private val Muted = Color(0xFF8C949E)

@Composable
internal fun SettingsChildScaffold(title: String, onBack: () -> Unit, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .statusBarsPadding(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = "Back",
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFE8E9ED))
                    .clickable(onClick = onBack)
                    .padding(4.dp),
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(title, fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
            Spacer(modifier = Modifier.weight(1f))
            Spacer(modifier = Modifier.size(36.dp))
        }
        content()
    }
}

// --- Activities ---

private enum class ActivityFilter { All, Today, Bookings, Payments }

private data class ActivityItem(
    val id: String,
    val title: String,
    val subtitle: String,
    val time: String,
    val kind: ActivityFilter,
)

@Composable
fun ActivitiesScreen(onBack: () -> Unit) {
    var filter by remember { mutableStateOf(ActivityFilter.All) }
    val activities = remember {
        listOf(
            ActivityItem("1", "Booking confirmed", "Eric Acmen · In-person", "Today 10:12", ActivityFilter.Bookings),
            ActivityItem("2", "Payment received", "Gift Fund · $75", "Today 09:40", ActivityFilter.Payments),
            ActivityItem("3", "Reschedule proposed", "Maya Chen", "Yesterday", ActivityFilter.Bookings),
            ActivityItem("4", "Invite sent", "John Smith joined as Collaborator", "Mon", ActivityFilter.All),
            ActivityItem("5", "Review posted", "5★ for Eric", "Sun", ActivityFilter.All),
            ActivityItem("6", "Gift sent", "$100 to EmBeLife User", "Sat", ActivityFilter.Payments),
        )
    }
    val filtered = activities.filter { filter == ActivityFilter.All || it.kind == filter || (filter == ActivityFilter.Today && it.time.startsWith("Today")) }

    SettingsChildScaffold("Activities", onBack) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(PageBG)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ActivityFilter.entries.forEach { f ->
                    val selected = filter == f
                    Text(
                        f.name,
                        color = if (selected) Color.White else EmBeColors.DarkText,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (selected) EmBeColors.BrandOrange else Color.White)
                            .clickable { filter = f }
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                    )
                }
            }
            filtered.forEachIndexed { index, item ->
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(
                            modifier = Modifier
                                .size(12.dp)
                                .clip(CircleShape)
                                .background(if (index == 0) EmBeColors.BrandOrange else Muted),
                        )
                        if (index < filtered.lastIndex) {
                            Box(modifier = Modifier.width(2.dp).height(56.dp).background(Color(0xFFE0E3E8)))
                        }
                    }
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color.White)
                            .then(
                                if (index == 0) Modifier.background(Color.White) else Modifier,
                            )
                            .padding(14.dp),
                    ) {
                        if (index == 0) {
                            Box(modifier = Modifier.fillMaxWidth().height(3.dp).background(EmBeColors.BrandOrange).padding(bottom = 8.dp))
                        }
                        Text(item.title, fontWeight = FontWeight.Bold, color = EmBeColors.DarkText)
                        Text(item.subtitle, color = Muted, fontSize = 13.sp)
                        Text(item.time, color = Muted, fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

// --- Dashboard ---

@Composable
fun DashboardScreen(appViewModel: AppViewModel, onBack: () -> Unit) {
    val active = appViewModel.bookings.count { it.status == BookingStatus.Booked }
    val requested = appViewModel.bookings.count { it.status == BookingStatus.Requested }
    val done = appViewModel.bookings.count { it.status == BookingStatus.Completed }

    SettingsChildScaffold("Dashboard", onBack) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(PageBG)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                DashTile("Active", "$active", EmBeColors.BrandOrange, Modifier.weight(1f))
                DashTile("Requests", "$requested", EmBeColors.LinkBlue, Modifier.weight(1f))
                DashTile("Done", "$done", Color(0xFF2EB873), Modifier.weight(1f))
            }
            ChartCard("Care hours") {
                SimpleBarChart(listOf(4f, 7f, 5f, 9f, 6f, 8f, 3f))
            }
            ChartCard("Service mix") {
                SimpleDonut()
            }
            ChartCard("Booking pipeline") {
                PipelineRow("Requested", requested, EmBeColors.LinkBlue)
                PipelineRow("Booked", active, EmBeColors.BrandOrange)
                PipelineRow("Completed", done, Color(0xFF2EB873))
            }
            ChartCard("Match quality") {
                SimpleLineChart(listOf(0.6f, 0.7f, 0.65f, 0.8f, 0.75f, 0.9f, 0.85f))
            }
        }
    }
}

@Composable
private fun DashTile(label: String, value: String, accent: Color, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.clip(RoundedCornerShape(14.dp)).background(Color.White).padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(label, color = Muted, fontSize = 12.sp)
        Text(value, color = accent, fontSize = 24.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun ChartCard(title: String, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color.White).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, fontWeight = FontWeight.Bold, color = EmBeColors.DarkText)
        content()
    }
}

@Composable
private fun SimpleBarChart(values: List<Float>) {
    val max = values.maxOrNull() ?: 1f
    Row(
        modifier = Modifier.fillMaxWidth().height(120.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        values.forEach { v ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .height((100 * (v / max)).dp)
                    .clip(RoundedCornerShape(topStart = 6.dp, topEnd = 6.dp))
                    .background(EmBeColors.BrandOrange.copy(alpha = 0.85f)),
            )
        }
    }
}

@Composable
private fun SimpleDonut() {
    Canvas(modifier = Modifier.fillMaxWidth().height(140.dp)) {
        val stroke = 28.dp.toPx()
        val diameter = size.minDimension - stroke
        val topLeft = Offset((size.width - diameter) / 2, (size.height - diameter) / 2)
        val arcSize = Size(diameter, diameter)
        drawArc(EmBeColors.BrandOrange, -90f, 140f, false, topLeft = topLeft, size = arcSize, style = Stroke(stroke))
        drawArc(EmBeColors.LinkBlue, 50f, 110f, false, topLeft = topLeft, size = arcSize, style = Stroke(stroke))
        drawArc(Color(0xFF2EB873), 160f, 110f, false, topLeft = topLeft, size = arcSize, style = Stroke(stroke))
    }
}

@Composable
private fun PipelineRow(label: String, count: Int, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(label, modifier = Modifier.width(90.dp), color = EmBeColors.DarkText, fontSize = 13.sp)
        Box(
            modifier = Modifier
                .weight(1f)
                .height(10.dp)
                .clip(RoundedCornerShape(5.dp))
                .background(Color(0xFFEEF0F4)),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth((count.coerceAtLeast(1) / 5f).coerceAtMost(1f))
                    .height(10.dp)
                    .clip(RoundedCornerShape(5.dp))
                    .background(color),
            )
        }
        Text("$count", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
    }
}

@Composable
private fun SimpleLineChart(values: List<Float>) {
    Canvas(modifier = Modifier.fillMaxWidth().height(120.dp)) {
        if (values.size < 2) return@Canvas
        val path = Path()
        values.forEachIndexed { i, v ->
            val x = size.width * i / (values.size - 1)
            val y = size.height * (1f - v)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        drawPath(path, EmBeColors.BrandOrange, style = Stroke(width = 4.dp.toPx()))
    }
}

// --- Password ---

private data class LinkedDevice(val id: String, val name: String, val detail: String)

@Composable
fun PasswordSecurityScreen(onBack: () -> Unit) {
    var current by remember { mutableStateOf("") }
    var next by remember { mutableStateOf("") }
    var confirm by remember { mutableStateOf("") }
    var showCurrent by remember { mutableStateOf(false) }
    var showNext by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    val devices = remember {
        listOf(
            LinkedDevice("1", "iPhone 15 Pro", "San Francisco · Active now"),
            LinkedDevice("2", "MacBook Pro", "San Francisco · 2h ago"),
            LinkedDevice("3", "iPad Air", "Oakland · Yesterday"),
            LinkedDevice("4", "Chrome · Windows", "Seattle · 3d ago"),
            LinkedDevice("5", "Pixel 8", "Remote · 1w ago"),
        )
    }

    fun valid(pw: String): Boolean {
        val hasUpper = pw.any { it.isUpperCase() }
        val hasLower = pw.any { it.isLowerCase() }
        val hasDigit = pw.any { it.isDigit() }
        val hasSpecial = pw.any { !it.isLetterOrDigit() }
        return pw.length >= 8 && hasUpper && hasLower && hasDigit && hasSpecial
    }

    SettingsChildScaffold("Password & Security", onBack) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(PageBG)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Column(
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color.White).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text("Change Password", fontWeight = FontWeight.Bold)
                PasswordField("Current password", current, showCurrent, { current = it }, { showCurrent = !showCurrent })
                PasswordField("New password", next, showNext, { next = it }, { showNext = !showNext })
                PasswordField("Confirm password", confirm, false, { confirm = it }, {})
                message?.let { Text(it, color = EmBeColors.ErrorCoral, fontSize = 12.sp) }
                PrimaryOrangeButton(text = "Change Password", onClick = {
                    message = when {
                        !valid(next) -> "Use 8+ chars with upper, lower, number, and special."
                        next != confirm -> "Passwords do not match."
                        else -> null.also { /* success */ }
                    }
                    if (message == null) message = "Password updated."
                })
            }
            Column(
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color.White).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Devices, null, tint = EmBeColors.BrandOrange)
                    Spacer(Modifier.width(8.dp))
                    Text("Your Devices", fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    Text(
                        "Log out all",
                        color = EmBeColors.BrandOrange,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFFFE4D6))
                            .clickable { }
                            .padding(horizontal = 10.dp, vertical = 6.dp),
                    )
                }
                devices.forEach { device ->
                    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                        Text(device.name, fontWeight = FontWeight.SemiBold)
                        Text(device.detail, color = Muted, fontSize = 13.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun PasswordField(
    label: String,
    value: String,
    visible: Boolean,
    onValueChange: (String) -> Unit,
    onToggle: () -> Unit,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        singleLine = true,
        visualTransformation = if (visible) VisualTransformation.None else PasswordVisualTransformation(),
        trailingIcon = {
            if (label != "Confirm password") {
                Icon(
                    if (visible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                    contentDescription = null,
                    modifier = Modifier.clickable(onClick = onToggle),
                )
            }
        },
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(10.dp),
    )
}

// --- User management ---

@Composable
fun UserManagementScreen(appViewModel: AppViewModel, onBack: () -> Unit) {
    var expandedUserIDs by remember { mutableStateOf(setOf<String>()) }
    var showInvite by remember { mutableStateOf(false) }
    val expandedPermissionKeys = remember { mutableStateMapOf<String, Set<FeatureAccessKey>>() }

    SettingsChildScaffold("User management", onBack) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(PageBG)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            PrimaryOrangeButton(text = "Invite User", onClick = { showInvite = true })
            appViewModel.managedUsers.forEach { user ->
                val expanded = expandedUserIDs.contains(user.id)
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color.White)
                        .clickable(enabled = user.role.canExpandPermissions && !user.invitePending) {
                            expandedUserIDs = if (expanded) expandedUserIDs - user.id else expandedUserIDs + user.id
                        }
                        .padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Box(
                            modifier = Modifier.size(40.dp).clip(CircleShape).background(Color(0xFFF2C726)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(user.initials, color = Color.White, fontWeight = FontWeight.Bold)
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            Text(user.firstName, fontWeight = FontWeight.Bold)
                            Text(user.role.displayTitle, color = Muted, fontSize = 13.sp)
                            if (user.invitePending) {
                                Text("Invite sent", color = Color(0xFF8C7AC7), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                        if (user.role.canExpandPermissions) {
                            Icon(Icons.Filled.ExpandMore, null, tint = Muted)
                        }
                    }
                    if (expanded) {
                        FeatureAccessList(
                            permissions = user.permissions,
                            nestedPermissions = user.nestedPermissions,
                            expandedKeys = expandedPermissionKeys[user.id].orEmpty(),
                            onToggleExpand = { key ->
                                val current = expandedPermissionKeys[user.id].orEmpty()
                                expandedPermissionKeys[user.id] =
                                    if (current.contains(key)) current - key else current + key
                            },
                            onToggle = { key, enabled ->
                                appViewModel.updateManagedUserPermission(user.id, key, enabled)
                            },
                            onToggleNested = { key, nestedID, enabled ->
                                appViewModel.updateManagedNestedPermission(user.id, key, nestedID, enabled)
                            },
                        )
                    }
                }
            }
        }
    }

    if (showInvite) {
        InviteUserSheet(appViewModel = appViewModel, onDismiss = { showInvite = false })
    }
}

@Composable
fun FeatureAccessList(
    permissions: Map<FeatureAccessKey, Boolean>,
    nestedPermissions: Map<FeatureAccessKey, List<com.embelife.app.model.NestedFeatureAccess>>,
    expandedKeys: Set<FeatureAccessKey>,
    onToggleExpand: (FeatureAccessKey) -> Unit,
    onToggle: (FeatureAccessKey, Boolean) -> Unit,
    onToggleNested: (FeatureAccessKey, String, Boolean) -> Unit,
    isEditable: Boolean = true,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        FeatureAccessKey.entries.forEach { key ->
            val enabled = permissions[key] == true
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (key.hasNestedItems) {
                        Icon(
                            Icons.Filled.ExpandMore,
                            null,
                            modifier = Modifier
                                .size(20.dp)
                                .clickable { onToggleExpand(key) },
                        )
                    } else {
                        Spacer(Modifier.width(20.dp))
                    }
                    Text(key.title, modifier = Modifier.weight(1f), fontSize = 14.sp)
                    Switch(
                        checked = enabled,
                        onCheckedChange = { if (isEditable) onToggle(key, it) },
                        enabled = isEditable,
                        colors = SwitchDefaults.colors(checkedTrackColor = Color(0xFF2EB8A0)),
                    )
                }
                if (key.hasNestedItems && expandedKeys.contains(key)) {
                    nestedPermissions[key].orEmpty().forEach { nested ->
                        Row(
                            modifier = Modifier.padding(start = 28.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(nested.title, modifier = Modifier.weight(1f), fontSize = 13.sp, color = Muted)
                            Switch(
                                checked = nested.isEnabled,
                                onCheckedChange = { if (isEditable) onToggleNested(key, nested.id, it) },
                                enabled = isEditable,
                                colors = SwitchDefaults.colors(checkedTrackColor = Color(0xFF2EB8A0)),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun InviteUserSheet(appViewModel: AppViewModel, onDismiss: () -> Unit) {
    var first by remember { mutableStateOf("") }
    var last by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var role by remember { mutableStateOf(TeamAccessRole.Collaborator) }
    var permissions by remember { mutableStateOf(FeatureAccessKey.defaults(role)) }
    var nested by remember { mutableStateOf(ManagedTeamUser.nestedDefaults()) }
    var expandedKeys by remember { mutableStateOf(setOf<FeatureAccessKey>()) }
    var showSuccess by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.4f))
            .clickable(onClick = onDismiss),
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp))
                .background(Color.White)
                .clickable(enabled = false) {}
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Invite User", fontWeight = FontWeight.Bold, fontSize = 20.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
            OutlinedTextField(first, { first = it }, label = { Text("First name *") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            OutlinedTextField(last, { last = it }, label = { Text("Last name") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            OutlinedTextField(email, { email = it }, label = { Text("Email *") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TeamAccessRole.inviteChoices.forEach { r ->
                    val selected = role == r
                    Text(
                        r.title,
                        color = if (selected) Color.White else EmBeColors.DarkText,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (selected) EmBeColors.BrandOrange else Color(0xFFF0F1F4))
                            .clickable {
                                role = r
                                permissions = FeatureAccessKey.defaults(r)
                            }
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                    )
                }
            }
            FeatureAccessList(
                permissions = permissions,
                nestedPermissions = nested,
                expandedKeys = expandedKeys,
                onToggleExpand = { key ->
                    expandedKeys = if (expandedKeys.contains(key)) expandedKeys - key else expandedKeys + key
                },
                onToggle = { key, enabled -> permissions = permissions.toMutableMap().also { it[key] = enabled } },
                onToggleNested = { key, nestedID, enabled ->
                    val items = nested[key]?.toMutableList() ?: return@FeatureAccessList
                    val idx = items.indexOfFirst { it.id == nestedID }
                    if (idx >= 0) {
                        items[idx] = items[idx].copy(isEnabled = enabled)
                        nested = nested.toMutableMap().also { it[key] = items }
                    }
                },
            )
            role.summaryBullets.forEach {
                Text("• $it", color = Color(0xFF8C7AC7), fontSize = 13.sp)
            }
            PrimaryOrangeButton(
                text = "Invite",
                enabled = first.isNotBlank() && email.isNotBlank(),
                onClick = {
                    appViewModel.inviteManagedUser(first, last, email, role, permissions, nested)
                    showSuccess = true
                },
            )
            Spacer(Modifier.height(12.dp))
        }

        if (showSuccess) {
            Column(
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(32.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(Color.White)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text("✓", color = Color(0xFF2EB873), fontSize = 40.sp, fontWeight = FontWeight.Bold)
                Text("Invitation Sent", fontWeight = FontWeight.Bold, fontSize = 20.sp)
                Text("We emailed $first an invite to join EmBeLife.", textAlign = TextAlign.Center, color = Muted)
                PrimaryOrangeButton(text = "Done", onClick = onDismiss)
            }
        }
    }
}
