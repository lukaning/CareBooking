package com.embelife.app.ui.onboarding

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.ui.components.PrimaryOrangeButton

private val PageBackground = Color(0xFFFCFCFD)
private val TaglineColor = Color(0xFF7A8089)

/** Port of `WelcomeStep`. */
@Composable
fun WelcomeStep(
    onContinue: () -> Unit,
    onSignUpIn: () -> Unit,
) {
    val screenHeight = LocalConfiguration.current.screenHeightDp
    // Mirrors the iOS clamp: min(380, max(280, screenHeight * 0.44)).
    val heroHeight = (screenHeight * 0.44f).coerceIn(280f, 380f)

    Column(modifier = Modifier.fillMaxSize().background(PageBackground)) {
        Box(modifier = Modifier.fillMaxWidth().height(heroHeight.dp)) {
            Image(
                painter = painterResource(R.drawable.onboarding_hero),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )

            Text(
                text = "Sign up/in",
                color = Color.White,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .statusBarsPadding()
                    .padding(top = 8.dp, end = 16.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(Color.Black.copy(alpha = 0.28f))
                    .clickable(onClick = onSignUpIn)
                    .padding(horizontal = 14.dp, vertical = 8.dp),
            )
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
        ) {
            Text(
                text = "Hi, 👋",
                color = Color.Black,
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 10.dp),
            )

            Text(
                text = "Welcome to",
                color = Color.Black,
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 2.dp),
            )

            Image(
                painter = painterResource(R.drawable.embelife_logo),
                contentDescription = "EmBeLife",
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .padding(top = 18.dp)
                    .height(52.dp)
                    .widthIn(max = 200.dp),
            )

            Text(
                text = "Find trustworthy help and support...",
                color = TaglineColor,
                fontSize = 15.sp,
                modifier = Modifier.padding(top = 16.dp),
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp)
                .padding(top = 12.dp, bottom = 16.dp),
        ) {
            PrimaryOrangeButton(text = "Next", onClick = onContinue)
        }
    }
}
