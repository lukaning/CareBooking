package com.embelife.app.ui.onboarding

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.location.LocationHelper
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import com.embelife.app.viewmodel.LocationChoice
import kotlin.math.min
import kotlin.math.roundToInt

private val TitleBlue = Color(0xFF1DA1F2)
private val ConfirmedGreen = Color(0xFF33AD61)
private val SliderInactive = Color(0xFFE0E3E8)

/** Port of `LocationStep`. */
@Composable
fun LocationStep(
    appViewModel: AppViewModel,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    var coordinate by remember {
        mutableStateOf(LocationHelper.SAMPLE_LATITUDE to LocationHelper.SAMPLE_LONGITUDE)
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions(),
    ) { granted ->
        // Denying leaves the panel collapsed on iOS; granting expands it.
        if (granted.values.any { it }) {
            coordinate = LocationHelper.lastKnownCoordinate(context)
            appViewModel.locationChoice = LocationChoice.Current
            appViewModel.locationConfirmed = false
        }
    }

    LaunchedEffect(appViewModel.locationChoice) {
        if (appViewModel.locationChoice == LocationChoice.Current) {
            coordinate = LocationHelper.lastKnownCoordinate(context)
        }
    }

    val currentAddressText = appViewModel.resolvedCurrentAddress
        .ifEmpty { LocationHelper.SAMPLE_ADDRESS }

    val canContinue = appViewModel.locationChoice != null && appViewModel.locationConfirmed

    Column(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = "Where do you need help?",
                color = EmBeColors.DarkText,
                fontSize = 28.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(top = 20.dp),
            )

            // Current location
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                LocationHeader(
                    title = "Use current location",
                    titleColor = TitleBlue,
                    isSelected = appViewModel.locationChoice == LocationChoice.Current,
                ) {
                    if (appViewModel.locationChoice == LocationChoice.Current) {
                        appViewModel.locationChoice = null
                        appViewModel.locationConfirmed = false
                    } else if (LocationHelper.hasPermission(context)) {
                        coordinate = LocationHelper.lastKnownCoordinate(context)
                        appViewModel.locationChoice = LocationChoice.Current
                        appViewModel.locationConfirmed = false
                    } else {
                        permissionLauncher.launch(LocationHelper.permissions)
                    }
                }

                if (appViewModel.locationChoice == LocationChoice.Current) {
                    Column(
                        modifier = Modifier.padding(start = 40.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Text(
                            text = currentAddressText,
                            color = EmBeColors.DarkText,
                            fontSize = 15.sp,
                        )

                        DistanceSelector(appViewModel = appViewModel)

                        ConfirmButton(
                            enabled = true,
                            isConfirmed = appViewModel.locationConfirmed,
                        ) {
                            appViewModel.resolvedCurrentAddress = currentAddressText
                            appViewModel.locationConfirmed = true
                        }

                        LocationMapPreview(
                            radiusMiles = appViewModel.searchRadiusMiles,
                        )
                    }
                }
            }

            // Custom location
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                LocationHeader(
                    title = "Customize location",
                    titleColor = Color.Black.copy(alpha = 0.75f),
                    isSelected = appViewModel.locationChoice == LocationChoice.Custom,
                ) {
                    if (appViewModel.locationChoice == LocationChoice.Custom) {
                        appViewModel.locationChoice = null
                    } else {
                        appViewModel.locationChoice = LocationChoice.Custom
                    }
                    appViewModel.locationConfirmed = false
                }

                if (appViewModel.locationChoice == LocationChoice.Custom) {
                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = Color.White,
                        shadowElevation = 4.dp,
                        modifier = Modifier.padding(start = 40.dp),
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            PanelTextField(
                                value = appViewModel.customAddress,
                                placeholder = "Address",
                                onValueChange = {
                                    appViewModel.customAddress = it
                                    appViewModel.locationConfirmed = false
                                },
                            )

                            PanelTextField(
                                value = appViewModel.customZipcode,
                                placeholder = "Zipcode",
                                keyboardType = KeyboardType.Number,
                                onValueChange = {
                                    appViewModel.customZipcode = it
                                    appViewModel.locationConfirmed = false
                                },
                            )

                            Text(
                                text = "Your address is used to confirm your account and will " +
                                    "not to be shared with any third parties",
                                color = EmBeColors.Grayscale70,
                                fontSize = 12.sp,
                            )

                            DistanceSelector(appViewModel = appViewModel)

                            ConfirmButton(
                                enabled = appViewModel.customAddress.isNotBlank(),
                                isConfirmed = appViewModel.locationConfirmed,
                            ) {
                                appViewModel.customLocation = listOf(
                                    appViewModel.customAddress,
                                    appViewModel.customZipcode,
                                ).filter { it.isNotEmpty() }.joinToString(", ")
                                appViewModel.locationConfirmed = true
                            }

                            LocationMapPreview(radiusMiles = appViewModel.searchRadiusMiles)
                        }
                    }
                }
            }
        }

        OnboardingBottomBar(title = "Next", enabled = canContinue, onClick = onContinue)
    }
}

@Composable
private fun LocationHeader(
    title: String,
    titleColor: Color,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        OnboardingRadioControl(isSelected = isSelected)

        Image(
            painter = painterResource(R.drawable.pin_icon),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier.size(40.dp),
        )

        Text(
            text = title,
            color = titleColor,
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun PanelTextField(
    value: String,
    placeholder: String,
    keyboardType: KeyboardType = KeyboardType.Text,
    onValueChange: (String) -> Unit,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(text = placeholder, color = EmBeColors.Grayscale60, fontSize = 15.sp) },
        singleLine = true,
        shape = RoundedCornerShape(12.dp),
        keyboardOptions = KeyboardOptions(
            keyboardType = keyboardType,
            imeAction = ImeAction.Done,
        ),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = Color.White,
            unfocusedContainerColor = Color.White,
            focusedBorderColor = EmBeColors.BrandOrange,
            unfocusedBorderColor = Color.Black.copy(alpha = 0.15f),
        ),
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun DistanceSelector(appViewModel: AppViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "Select Distance",
                color = EmBeColors.DarkText,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = distanceLabel(appViewModel.searchRadiusMiles),
                color = EmBeColors.BrandOrange,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
            )
        }

        // Left continuous: the iOS slider uses step 1 over 1...250, but drawing 249
        // Compose tick marks merges into a solid bar.
        Slider(
            value = appViewModel.searchRadiusMiles,
            onValueChange = {
                appViewModel.searchRadiusMiles = it
                appViewModel.locationConfirmed = false
            },
            valueRange = 1f..250f,
            colors = SliderDefaults.colors(
                thumbColor = EmBeColors.BrandOrange,
                activeTrackColor = EmBeColors.BrandOrange,
                inactiveTrackColor = SliderInactive,
            ),
        )

        Row(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "1 mile",
                color = EmBeColors.DarkText,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "250 miles",
                color = EmBeColors.DarkText,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

private fun distanceLabel(miles: Float): String {
    val value = miles.roundToInt()
    return if (value == 1) "1 mile" else "$value miles"
}

@Composable
private fun ConfirmButton(
    enabled: Boolean,
    isConfirmed: Boolean,
    onClick: () -> Unit,
) {
    val active = enabled || isConfirmed
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(
                (if (isConfirmed) ConfirmedGreen else EmBeColors.BrandOrange)
                    .copy(alpha = if (active) 1f else 0.5f),
            )
            .clickable(enabled = active, onClick = onClick)
            .padding(vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (isConfirmed) {
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(20.dp),
            )
            Spacer(modifier = Modifier.size(8.dp))
        }
        Text(
            text = if (isConfirmed) "Confirmed" else "Confirm",
            color = Color.White,
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

/**
 * Stand-in for the iOS `LocationMapPreview`, which renders a non-interactive MapKit
 * snapshot with a radius overlay. Drawing the radius on a Canvas keeps the step
 * dependency-free; swapping in a real basemap only needs this composable replaced.
 */
@Composable
private fun LocationMapPreview(radiusMiles: Float) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(110.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color(0xFFE8EDF2))
            .border(1.dp, EmBeColors.CardBorder, RoundedCornerShape(12.dp)),
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val centre = Offset(size.width / 2f, size.height / 2f)
            // 250 miles fills the preview; smaller radii scale down proportionally.
            val maxRadius = min(size.width, size.height) / 2f * 0.9f
            val radius = maxRadius * (radiusMiles / 250f).coerceIn(0.08f, 1f)

            drawCircle(color = Color(0x47739FF2), radius = radius, center = centre)
            drawCircle(
                color = Color(0x8C599EE6),
                radius = radius,
                center = centre,
                style = androidx.compose.ui.graphics.drawscope.Stroke(width = 2f),
            )
        }

        Image(
            painter = painterResource(R.drawable.pin_icon),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .align(Alignment.Center)
                .size(28.dp),
        )
    }
}
