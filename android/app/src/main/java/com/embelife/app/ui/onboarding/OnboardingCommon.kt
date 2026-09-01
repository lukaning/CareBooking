package com.embelife.app.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.embelife.app.ui.components.HeroHeaderImage
import com.embelife.app.ui.components.PrimaryBlackButton
import com.embelife.app.ui.theme.EmBeColors

/** Port of `OnboardingStepContainer` — hero image above the step content. */
@Composable
fun OnboardingStepContainer(content: @Composable () -> Unit) {
    Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
        OnboardingHero()
        content()
    }
}

/** Port of `OnboardingHero`. */
@Composable
fun OnboardingHero() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(EmBeColors.BrandOrange)
            .statusBarsPadding(),
    ) {
        HeroHeaderImage()
    }
}

/**
 * Port of `OnboardingRadioControl` — white disc with a light gray ring; the selected
 * state adds an orange centre dot.
 */
@Composable
fun OnboardingRadioControl(
    isSelected: Boolean,
    size: Int = 26,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .size(size.dp)
            .background(Color.White, CircleShape)
            .border(1.5.dp, Color(0xFFD1D1D5), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (isSelected) {
            Box(
                modifier = Modifier
                    .size((size * 0.5f).dp)
                    .background(EmBeColors.BrandOrange, CircleShape),
            )
        }
    }
}

/** Port of `onboardingBottomBar` — pinned black primary action. */
@Composable
fun OnboardingBottomBar(
    title: String,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White)
            .navigationBarsPadding()
            .padding(horizontal = 20.dp, vertical = 16.dp),
    ) {
        PrimaryBlackButton(text = title, enabled = enabled, onClick = onClick)
    }
}
