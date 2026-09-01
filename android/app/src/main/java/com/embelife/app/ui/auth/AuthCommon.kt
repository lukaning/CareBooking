package com.embelife.app.ui.auth

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.layout.offset
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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.ui.theme.EmBeColors

/** Port of `AuthHeader` — orange banner with title row, headline and subtitle. */
@Composable
fun AuthHeader(
    title: String,
    headline: String,
    subtitle: String,
    onBack: (() -> Unit)? = null,
    showsBackControl: Boolean = false,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(EmBeColors.BrandOrange)
            .statusBarsPadding()
            .padding(horizontal = 24.dp)
            .padding(top = 8.dp, bottom = 36.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(modifier = Modifier.fillMaxWidth().padding(top = 4.dp)) {
            Text(
                text = title,
                color = Color.White,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().align(Alignment.Center),
            )
            if (showsBackControl || onBack != null) {
                AuthBackButton(
                    onClick = onBack,
                    modifier = Modifier.align(Alignment.CenterStart),
                )
            }
        }

        Text(text = headline, color = Color.White, fontSize = 32.sp, fontWeight = FontWeight.Bold)

        Text(
            text = subtitle,
            color = Color.White.copy(alpha = 0.92f),
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

/** Port of `AuthBackButton` — 44pt circular chevron. */
@Composable
fun AuthBackButton(
    onClick: (() -> Unit)?,
    tint: Color = Color.White,
    background: Color = Color.White.copy(alpha = 0.2f),
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(background)
            .clickable(enabled = onClick != null) { onClick?.invoke() },
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
            contentDescription = "Back",
            tint = tint,
        )
    }
}

/**
 * Port of `AuthFormSheet` — white rounded sheet that overlaps the orange header by 20pt.
 */
@Composable
fun AuthFormSheet(
    topPadding: Int = 28,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .offset(y = (-20).dp)
            .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp))
            .background(Color.White),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = topPadding.dp, bottom = 32.dp),
        ) {
            content()
        }
    }
}

/** Port of `PlainAuthScreen` — white screen with a dark chevron in the top-left. */
@Composable
fun PlainAuthScreen(
    onBack: (() -> Unit)?,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .statusBarsPadding(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(top = 8.dp),
        ) {
            AuthBackButton(
                onClick = onBack,
                tint = EmBeColors.DarkText,
                background = EmBeColors.InputFill,
            )
            Spacer(modifier = Modifier.weight(1f))
        }

        content()
    }
}

/** Port of `SocialSignInRow`. */
@Composable
fun SocialSignInRow(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            HorizontalDivider(
                modifier = Modifier.weight(1f),
                color = EmBeColors.Grayscale60.copy(alpha = 0.35f),
            )
            Text(
                text = "Or Sign In with",
                color = EmBeColors.Grayscale60,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
            )
            HorizontalDivider(
                modifier = Modifier.weight(1f),
                color = EmBeColors.Grayscale60.copy(alpha = 0.35f),
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            SocialButton(R.drawable.google_logo)
            SocialButton(R.drawable.apple_logo)
        }
    }
}

@Composable
private fun SocialButton(imageRes: Int) {
    Box(
        modifier = Modifier
            .width(72.dp)
            .height(52.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(EmBeColors.InputFill)
            // Social auth is a placeholder for the MVP, same as iOS.
            .clickable { },
        contentAlignment = Alignment.Center,
    ) {
        Image(
            painter = painterResource(imageRes),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier.size(28.dp),
        )
    }
}

/** Port of `TermsFooter` — mixed-weight legal line. */
@Composable
fun TermsFooter(modifier: Modifier = Modifier) {
    val text = buildAnnotatedString {
        withStyle(SpanStyle(color = EmBeColors.Grayscale70)) {
            append("By signing up you agree to our ")
        }
        withStyle(SpanStyle(color = EmBeColors.DarkText, fontWeight = FontWeight.SemiBold)) {
            append("Terms")
        }
        withStyle(SpanStyle(color = EmBeColors.Grayscale70)) {
            append(" and ")
        }
        withStyle(SpanStyle(color = EmBeColors.DarkText, fontWeight = FontWeight.SemiBold)) {
            append("Conditions of Use")
        }
    }

    Text(
        text = text,
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        textAlign = TextAlign.Center,
        modifier = modifier.fillMaxWidth(),
    )
}
