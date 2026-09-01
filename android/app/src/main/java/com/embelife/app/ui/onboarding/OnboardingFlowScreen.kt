package com.embelife.app.ui.onboarding

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.embelife.app.viewmodel.AppViewModel

/** Port of `OnboardingFlowView`. */
@Composable
fun OnboardingFlowScreen(appViewModel: AppViewModel) {
    var step by remember { mutableIntStateOf(0) }

    LaunchedEffect(appViewModel.skipWelcomeStep) {
        if (appViewModel.skipWelcomeStep) {
            appViewModel.skipWelcomeStep = false
            if (step == 0) step = 1
        }
    }

    Crossfade(
        targetState = step,
        animationSpec = tween(durationMillis = 200),
        label = "onboarding-step",
    ) { current ->
        when (current) {
            0 -> WelcomeStep(
                onContinue = { step = 1 },
                onSignUpIn = { appViewModel.showAuth() },
            )

            1 -> OnboardingStepContainer {
                RoleLanguageStep(appViewModel = appViewModel, onContinue = { step = 2 })
            }

            2 -> OnboardingStepContainer {
                ServiceNeedsStep(appViewModel = appViewModel, onContinue = { step = 3 })
            }

            else -> OnboardingStepContainer {
                LocationStep(
                    appViewModel = appViewModel,
                    onContinue = { appViewModel.finishOnboarding() },
                )
            }
        }
    }
}
