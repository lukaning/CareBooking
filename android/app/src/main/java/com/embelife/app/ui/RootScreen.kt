package com.embelife.app.ui

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.embelife.app.ui.auth.AuthFlowScreen
import com.embelife.app.ui.main.MainTabScreen
import com.embelife.app.ui.onboarding.OnboardingFlowScreen
import com.embelife.app.viewmodel.AppFlow
import com.embelife.app.viewmodel.AppViewModel

/** Port of `RootView` in `EmBeLifeApp.swift`. */
@Composable
fun RootScreen(appViewModel: AppViewModel) {
    Box(modifier = Modifier.fillMaxSize().background(Color.White)) {
        Crossfade(
            targetState = appViewModel.flow,
            animationSpec = tween(durationMillis = 250),
            label = "app-flow",
        ) { flow ->
            when (flow) {
                AppFlow.Auth -> AuthFlowScreen(appViewModel = appViewModel)
                AppFlow.Onboarding -> OnboardingFlowScreen(appViewModel = appViewModel)
                AppFlow.Main -> MainTabScreen(appViewModel = appViewModel)
            }
        }
    }
}
