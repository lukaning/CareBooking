package com.embelife.app.ui.messages

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.ChatMessage
import com.embelife.app.model.ChatSender
import com.embelife.app.model.MessageThread
import com.embelife.app.ui.theme.EmBeColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.util.UUID

private val PageBG = Color(0xFFF2F2F7)
private val NameColor = Color(0xFF2E3D5C)
private val PreviewColor = Color(0xFF8C949E)
private val TimeColor = Color(0xFFA6ADB8)
private val UnreadDot = Color(0xFF338CF2)
private val OnlineDot = Color(0xFF4DC773)
private val OutgoingBubble = Color(0xFF4D5C73)
private val IncomingBubble = Color(0xFFE8EAF0)

@Composable
fun MessagesScreen(contentPadding: PaddingValues) {
    val threads = remember {
        mutableStateListOf<MessageThread>().apply { addAll(MessageThread.samples) }
    }
    var selectedThreadID by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(selectedThreadID) {
        while (true) {
            delay(3200)
            val index = threads.indexOfFirst { it.id == "msg-1" }
            if (index < 0) return@LaunchedEffect
            if (selectedThreadID != "msg-1") {
                val thread = threads[index]
                val typing = !thread.isTyping
                threads[index] = thread.copy(
                    isOnline = true,
                    isTyping = typing,
                    preview = if (typing) "Typing..." else thread.lastMessageText,
                )
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PageBG)
            .padding(bottom = contentPadding.calculateBottomPadding()),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.White)
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Spacer(modifier = Modifier.width(32.dp))
                Text(
                    "Messages",
                    color = EmBeColors.DarkText,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                )
                Icon(Icons.Filled.MoreHoriz, contentDescription = "More", tint = EmBeColors.DarkText)
            }

            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(threads, key = { it.id }) { thread ->
                    MessageRow(thread) {
                        val index = threads.indexOfFirst { it.id == thread.id }
                        if (index >= 0) {
                            threads[index] = threads[index].copy(isUnread = false, isTyping = false)
                        }
                        selectedThreadID = thread.id
                    }
                }
            }
        }

        selectedThreadID?.let { id ->
            val index = threads.indexOfFirst { it.id == id }
            if (index >= 0) {
                ConversationScreen(
                    thread = threads[index],
                    onBack = { selectedThreadID = null },
                    onUpdate = { updated -> threads[index] = updated },
                )
            }
        }
    }
}

@Composable
private fun MessageRow(thread: MessageThread, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White)
            .clickable(onClick = onClick)
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        MessageAvatar(thread.initials, thread.avatarColor, thread.isOnline, 48.dp)
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row {
                Text(
                    thread.name,
                    color = NameColor,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                Text(thread.timeLabel, color = TimeColor, fontSize = 12.sp)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    if (thread.isTyping) "Typing..." else thread.preview,
                    color = if (thread.isTyping) EmBeColors.BrandOrange else PreviewColor,
                    fontSize = 14.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                if (thread.isUnread) {
                    Box(
                        modifier = Modifier
                            .size(9.dp)
                            .clip(CircleShape)
                            .background(UnreadDot),
                    )
                }
            }
        }
    }
}

@Composable
private fun ConversationScreen(
    thread: MessageThread,
    onBack: () -> Unit,
    onUpdate: (MessageThread) -> Unit,
) {
    var draft by remember { mutableStateOf("") }
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    LaunchedEffect(thread.messages.size) {
        if (thread.messages.isNotEmpty()) {
            listState.animateScrollToItem(thread.messages.lastIndex)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .imePadding(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(
                Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = EmBeColors.DarkText,
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFE8E9ED))
                    .clickable(onClick = onBack)
                    .padding(6.dp),
            )
            MessageAvatar(thread.initials, thread.avatarColor, thread.isOnline, 40.dp)
            Column(modifier = Modifier.weight(1f)) {
                Text(thread.name, color = NameColor, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                Text(
                    if (thread.isOnline) "Online" else "Offline",
                    color = if (thread.isOnline) OnlineDot else PreviewColor,
                    fontSize = 12.sp,
                )
            }
            Icon(Icons.Filled.MoreHoriz, contentDescription = null, tint = EmBeColors.DarkText)
        }

        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(PageBG),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            items(thread.messages, key = { it.id }) { message ->
                val mine = message.sender == ChatSender.Me
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start,
                ) {
                    Text(
                        message.text,
                        color = if (mine) Color.White else EmBeColors.DarkText,
                        fontSize = 15.sp,
                        modifier = Modifier
                            .fillMaxWidth(0.82f)
                            .clip(RoundedCornerShape(16.dp))
                            .background(if (mine) OutgoingBubble else IncomingBubble)
                            .padding(horizontal = 14.dp, vertical = 10.dp),
                    )
                }
            }
            if (thread.isTyping) {
                item {
                    Text(
                        "Typing…",
                        color = EmBeColors.BrandOrange,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            BasicTextField(
                value = draft,
                onValueChange = { draft = it },
                cursorBrush = SolidColor(EmBeColors.BrandOrange),
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(22.dp))
                    .background(PageBG)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                decorationBox = { inner ->
                    Box {
                        if (draft.isEmpty()) {
                            Text("Message…", color = PreviewColor, fontSize = 15.sp)
                        }
                        inner()
                    }
                },
            )
            Icon(
                Icons.AutoMirrored.Filled.Send,
                contentDescription = "Send",
                tint = Color.White,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(if (draft.isBlank()) EmBeColors.Grayscale60 else EmBeColors.BrandOrange)
                    .clickable(enabled = draft.isNotBlank()) {
                        val text = draft.trim()
                        draft = ""
                        val sent = ChatMessage(
                            id = UUID.randomUUID().toString(),
                            text = text,
                            sender = ChatSender.Me,
                            sentAt = LocalDateTime.now(),
                        )
                        val afterSend = thread.copy(
                            messages = thread.messages + sent,
                            preview = text,
                            timeLabel = "Now",
                            isTyping = false,
                        )
                        onUpdate(afterSend)
                        scope.launch {
                            delay(1200)
                            val reply = ChatMessage(
                                id = UUID.randomUUID().toString(),
                                text = "Thanks — I’ll get back to you shortly.",
                                sender = ChatSender.Them,
                                sentAt = LocalDateTime.now(),
                            )
                            onUpdate(
                                afterSend.copy(
                                    messages = afterSend.messages + reply,
                                    preview = reply.text,
                                    timeLabel = "Now",
                                ),
                            )
                        }
                    }
                    .padding(10.dp),
            )
        }
    }
}

@Composable
private fun MessageAvatar(initials: String, color: Color, isOnline: Boolean, size: Dp) {
    Box(modifier = Modifier.size(size)) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clip(CircleShape)
                .background(color),
            contentAlignment = Alignment.Center,
        ) {
            Text(initials, color = Color.White, fontWeight = FontWeight.Bold, fontSize = (size.value * 0.32f).sp)
        }
        if (isOnline) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .size(size * 0.28f)
                    .clip(CircleShape)
                    .background(Color.White)
                    .padding(2.dp)
                    .clip(CircleShape)
                    .background(OnlineDot),
            )
        }
    }
}
