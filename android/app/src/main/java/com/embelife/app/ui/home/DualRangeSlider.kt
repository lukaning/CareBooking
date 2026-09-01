package com.embelife.app.ui.home

import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.embelife.app.ui.theme.EmBeColors
import androidx.compose.foundation.Canvas
import kotlin.math.abs
import kotlin.math.roundToInt

private val TrackInactive = Color(0xFFE0E3E8)

/**
 * Port of the iOS `DualRangeSlider`. Material's `RangeSlider` is close, but the iOS
 * control draws a thinner track with larger white handles, so this keeps the drawing
 * explicit to match.
 */
@Composable
fun DualRangeSlider(
    minValue: Float,
    maxValue: Float,
    bounds: ClosedFloatingPointRange<Float>,
    onValueChange: (Float, Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    val density = LocalDensity.current
    val handleRadiusPx = with(density) { 12.dp.toPx() }
    val trackHeightPx = with(density) { 4.dp.toPx() }

    var widthPx by remember { mutableFloatStateOf(0f) }
    var activeHandle by remember { mutableStateOf<Handle?>(null) }

    val span = (bounds.endInclusive - bounds.start).takeIf { it > 0f } ?: 1f

    fun fractionOf(value: Float) = ((value - bounds.start) / span).coerceIn(0f, 1f)

    fun valueAt(x: Float): Float {
        val usable = (widthPx - handleRadiusPx * 2f).takeIf { it > 0f } ?: return bounds.start
        val fraction = ((x - handleRadiusPx) / usable).coerceIn(0f, 1f)
        return (bounds.start + fraction * span).roundToInt().toFloat()
    }

    fun centerX(value: Float): Float {
        val usable = widthPx - handleRadiusPx * 2f
        return handleRadiusPx + fractionOf(value) * usable
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(40.dp)
            .pointerInput(bounds, widthPx) {
                detectDragGestures(
                    onDragStart = { offset ->
                        activeHandle = if (
                            abs(offset.x - centerX(minValue)) <= abs(offset.x - centerX(maxValue))
                        ) {
                            Handle.Min
                        } else {
                            Handle.Max
                        }
                        applyDrag(
                            handle = activeHandle,
                            newValue = valueAt(offset.x),
                            minValue = minValue,
                            maxValue = maxValue,
                            onValueChange = onValueChange,
                        )
                    },
                    onDragEnd = { activeHandle = null },
                    onDragCancel = { activeHandle = null },
                    onDrag = { change, _ ->
                        applyDrag(
                            handle = activeHandle,
                            newValue = valueAt(change.position.x),
                            minValue = minValue,
                            maxValue = maxValue,
                            onValueChange = onValueChange,
                        )
                    },
                )
            },
    ) {
        Canvas(modifier = Modifier.fillMaxWidth().height(40.dp)) {
            widthPx = size.width
            val centreY = size.height / 2f
            val usable = size.width - handleRadiusPx * 2f
            val minX = handleRadiusPx + fractionOf(minValue) * usable
            val maxX = handleRadiusPx + fractionOf(maxValue) * usable

            drawRoundRect(
                color = TrackInactive,
                topLeft = Offset(handleRadiusPx, centreY - trackHeightPx / 2f),
                size = androidx.compose.ui.geometry.Size(usable, trackHeightPx),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(trackHeightPx / 2f),
            )

            drawRoundRect(
                color = EmBeColors.BrandOrange,
                topLeft = Offset(minX, centreY - trackHeightPx / 2f),
                size = androidx.compose.ui.geometry.Size(
                    (maxX - minX).coerceAtLeast(0f),
                    trackHeightPx,
                ),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(trackHeightPx / 2f),
            )

            listOf(minX, maxX).forEach { x ->
                drawCircle(color = Color.White, radius = handleRadiusPx, center = Offset(x, centreY))
                drawCircle(
                    color = EmBeColors.BrandOrange,
                    radius = handleRadiusPx,
                    center = Offset(x, centreY),
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = 3f),
                )
            }
        }
    }
}

private enum class Handle { Min, Max }

private fun applyDrag(
    handle: Handle?,
    newValue: Float,
    minValue: Float,
    maxValue: Float,
    onValueChange: (Float, Float) -> Unit,
) {
    when (handle) {
        Handle.Min -> onValueChange(newValue.coerceAtMost(maxValue), maxValue)
        Handle.Max -> onValueChange(minValue, newValue.coerceAtLeast(minValue))
        null -> Unit
    }
}
