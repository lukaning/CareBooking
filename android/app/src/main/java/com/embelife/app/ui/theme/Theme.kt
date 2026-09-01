package com.embelife.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/**
 * Direct port of `EmBeLife/Theme/Theme.swift`. The first four come from asset catalog
 * colorsets; the rest are sRGB literals declared inline in the Swift enum.
 */
object EmBeColors {
    val BrandOrange = Color(0xFFF15925)
    val InputFill = Color(0xFFF6F8FE)
    val LinkBlue = Color(0xFF5A73D8)
    val ErrorCoral = Color(0xFFF2A8A4)
    val Grayscale70 = Color(0xFF78828A)
    val Grayscale60 = Color(0xFF9CA4AB)
    val DarkText = Color(0xFF0E111A)
    val MutedText = Color(0xFF9393AA)
    val CardBorder = Color(0xFFEFEFF3)
    val ProfilePill = Color(0xFFF0F4F9)
    val SegmentBG = Color(0xFFF0F4F9)
}

private val EmBeLightColors = lightColorScheme(
    primary = EmBeColors.BrandOrange,
    onPrimary = Color.White,
    background = Color.White,
    onBackground = EmBeColors.DarkText,
    surface = Color.White,
    onSurface = EmBeColors.DarkText,
    error = EmBeColors.ErrorCoral,
)

/**
 * The iOS app is light-only, so dark mode intentionally reuses the light scheme rather
 * than inventing colors the design doesn't define.
 */
@Composable
fun EmBeLifeTheme(
    @Suppress("UNUSED_PARAMETER") darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = EmBeLightColors,
        typography = EmBeTypography,
        content = content,
    )
}
