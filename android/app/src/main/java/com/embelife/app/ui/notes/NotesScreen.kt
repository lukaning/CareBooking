package com.embelife.app.ui.notes

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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.NotesScreenPhase
import com.embelife.app.model.VoiceConversationPhase
import com.embelife.app.model.VoiceNoteSample
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import kotlinx.coroutines.delay

private val UserBubble = Color(0xFFE6D6F0)
private val AiBubble = Color(0xFFD1E6FA)
private val PageBG = Color(0xFFF7F7F9)

/** Port of `NotesView` — Hands-free voice assistant demo. */
@Composable
fun NotesScreen(contentPadding: PaddingValues) {
    var phase by remember { mutableStateOf(NotesScreenPhase.Welcome) }
    var conversationPhase by remember { mutableStateOf(VoiceConversationPhase.Listening) }
    var isPlaying by remember { mutableStateOf(false) }
    var showTypeSheet by remember { mutableStateOf(false) }
    var typedInput by remember { mutableStateOf("") }

    LaunchedEffect(phase) {
        if (phase != NotesScreenPhase.Conversation) return@LaunchedEffect
        conversationPhase = VoiceConversationPhase.Listening
        delay(1600)
        conversationPhase = VoiceConversationPhase.UserTranscript
        delay(2400)
        conversationPhase = VoiceConversationPhase.Playback
        isPlaying = true
        delay(2000)
        isPlaying = false
        conversationPhase = VoiceConversationPhase.AiReply
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageBG)
            .padding(bottom = contentPadding.calculateBottomPadding()),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(vertical = 12.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text("Hands-free", color = EmBeColors.DarkText, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        }

        when (phase) {
            NotesScreenPhase.Welcome -> WelcomePhase(onStart = { phase = NotesScreenPhase.Ready })
            NotesScreenPhase.Ready -> ReadyPhase(onMic = { phase = NotesScreenPhase.Conversation })
            NotesScreenPhase.Conversation -> ConversationPhase(
                conversationPhase = conversationPhase,
                isPlaying = isPlaying,
                showTypeSheet = showTypeSheet,
                typedInput = typedInput,
                onTogglePlay = { isPlaying = !isPlaying },
                onShowType = { showTypeSheet = true },
                onHideType = { showTypeSheet = false },
                onTypedChange = { typedInput = it },
                onEnd = {
                    phase = NotesScreenPhase.Welcome
                    conversationPhase = VoiceConversationPhase.Listening
                },
            )
        }
    }
}

@Composable
private fun WelcomePhase(onStart: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(96.dp)
                .clip(CircleShape)
                .background(EmBeColors.BrandOrange.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Mic, contentDescription = null, tint = EmBeColors.BrandOrange, modifier = Modifier.size(44.dp))
        }
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            "Hands-free assistant",
            color = EmBeColors.DarkText,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(10.dp))
        Text(
            "Speak naturally to find care, book visits, and manage tasks without typing.",
            color = EmBeColors.MutedText,
            fontSize = 15.sp,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(28.dp))
        PrimaryOrangeButton(text = "Get Started", onClick = onStart)
    }
}

@Composable
private fun ReadyPhase(onMic: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("Tap to speak", color = EmBeColors.MutedText, fontSize = 16.sp)
        Spacer(modifier = Modifier.height(24.dp))
        Box(
            modifier = Modifier
                .size(120.dp)
                .clip(CircleShape)
                .background(EmBeColors.BrandOrange)
                .clickable(onClick = onMic),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Mic, contentDescription = "Start", tint = Color.White, modifier = Modifier.size(52.dp))
        }
    }
}

@Composable
private fun ConversationPhase(
    conversationPhase: VoiceConversationPhase,
    isPlaying: Boolean,
    showTypeSheet: Boolean,
    typedInput: String,
    onTogglePlay: () -> Unit,
    onShowType: () -> Unit,
    onHideType: () -> Unit,
    onTypedChange: (String) -> Unit,
    onEnd: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(12) { index ->
                val height = if (conversationPhase == VoiceConversationPhase.Listening) {
                    (12 + (index % 5) * 6).dp
                } else {
                    10.dp
                }
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(height)
                        .clip(RoundedCornerShape(4.dp))
                        .background(EmBeColors.BrandOrange.copy(alpha = if (conversationPhase == VoiceConversationPhase.Listening) 0.85f else 0.25f)),
                )
            }
        }

        if (conversationPhase != VoiceConversationPhase.Listening) {
            Text(
                VoiceNoteSample.userTranscript,
                color = EmBeColors.DarkText,
                fontSize = 15.sp,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(UserBubble)
                    .padding(14.dp),
            )
            Text(VoiceNoteSample.userTime, color = EmBeColors.MutedText, fontSize = 12.sp)
        }

        if (conversationPhase == VoiceConversationPhase.Playback ||
            conversationPhase == VoiceConversationPhase.AiReply
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White)
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Icon(
                    if (isPlaying) Icons.Filled.Stop else Icons.Filled.PlayArrow,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(EmBeColors.BrandOrange)
                        .clickable(onClick = onTogglePlay)
                        .padding(8.dp),
                )
                Column(modifier = Modifier.weight(1f)) {
                    Text("Voice note", color = EmBeColors.DarkText, fontWeight = FontWeight.SemiBold)
                    Text(VoiceNoteSample.audioDuration, color = EmBeColors.MutedText, fontSize = 12.sp)
                }
                Text("Translate", color = EmBeColors.LinkBlue, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            }
        }

        if (conversationPhase == VoiceConversationPhase.AiReply) {
            Text(
                VoiceNoteSample.assistantReply,
                color = EmBeColors.DarkText,
                fontSize = 15.sp,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(AiBubble)
                    .padding(14.dp),
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                "Type",
                color = EmBeColors.DarkText,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFFE8EAF0))
                    .clickable(onClick = onShowType)
                    .padding(vertical = 14.dp),
            )
            Text(
                "End",
                color = Color.White,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(12.dp))
                    .background(EmBeColors.BrandOrange)
                    .clickable(onClick = onEnd)
                    .padding(vertical = 14.dp),
            )
        }

        if (showTypeSheet) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text("Type a message", fontWeight = FontWeight.Bold, color = EmBeColors.DarkText)
                androidx.compose.material3.OutlinedTextField(
                    value = typedInput,
                    onValueChange = onTypedChange,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Ask EmBeLife…") },
                )
                PrimaryOrangeButton(text = "Send", onClick = onHideType)
            }
        }
    }
}
