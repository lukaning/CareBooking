package com.embelife.app.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.ui.theme.EmBeColors

/** Port of `PrimaryOrangeButtonStyle`. */
@Composable
fun PrimaryOrangeButton(
    text: String,
    enabled: Boolean = true,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    FilledPrimaryButton(
        text = text,
        fill = EmBeColors.BrandOrange,
        enabled = enabled,
        pressedAlpha = 0.85f,
        modifier = modifier,
        onClick = onClick,
    )
}

/** Port of `PrimaryBlackButtonStyle`. */
@Composable
fun PrimaryBlackButton(
    text: String,
    enabled: Boolean = true,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    FilledPrimaryButton(
        text = text,
        fill = Color.Black,
        enabled = enabled,
        pressedAlpha = 0.8f,
        modifier = modifier,
        onClick = onClick,
    )
}

@Composable
private fun FilledPrimaryButton(
    text: String,
    fill: Color,
    enabled: Boolean,
    pressedAlpha: Float,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val interactionSource = remember { MutableInteractionSource() }
    val pressed by interactionSource.collectIsPressedAsState()
    val alpha = when {
        !enabled -> 0.45f
        pressed -> pressedAlpha
        else -> 1f
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(fill.copy(alpha = alpha))
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                enabled = enabled,
                onClick = onClick,
            )
            // Matches the 18pt vertical padding both iOS button styles use.
            .padding(vertical = 18.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = text, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
    }
}

/** Port of `HeroHeaderImage` — full-width 16:9 hero. */
@Composable
fun HeroHeaderImage(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(16f / 9f),
    ) {
        Image(
            painter = painterResource(R.drawable.onboarding_hero),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

/** Port of `EmBeLifeLogo` — orange "Em" disc followed by the BeLife wordmark. */
@Composable
fun EmBeLifeLogo(
    markSize: Int = 44,
    wordSize: Int = 28,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            modifier = Modifier
                .size(markSize.dp)
                .background(EmBeColors.BrandOrange, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "Em",
                color = Color.White,
                fontSize = (markSize * 0.38f).sp,
                fontWeight = FontWeight.Bold,
            )
        }

        Row(verticalAlignment = Alignment.Top) {
            Text(
                text = "BeLife",
                color = EmBeColors.BrandOrange,
                fontSize = wordSize.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = "™",
                color = EmBeColors.BrandOrange,
                fontSize = (wordSize * 0.38f).sp,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(top = 2.dp),
            )
        }
    }
}

/** Port of `AuthTextField` — labelled field on `inputFill` with a secure-entry toggle. */
@Composable
fun AuthTextField(
    title: String,
    placeholder: String,
    value: String,
    onValueChange: (String) -> Unit,
    isSecure: Boolean = false,
    imeAction: ImeAction = ImeAction.Next,
    modifier: Modifier = Modifier,
) {
    var showPassword by remember { mutableStateOf(false) }
    val isEmail = title.lowercase().contains("mail")

    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = title,
            color = EmBeColors.Grayscale70,
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
        )

        TextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = {
                Text(text = placeholder, color = EmBeColors.Grayscale60, fontSize = 17.sp)
            },
            singleLine = true,
            textStyle = TextStyle(color = EmBeColors.DarkText, fontSize = 17.sp),
            visualTransformation = if (isSecure && !showPassword) {
                PasswordVisualTransformation()
            } else {
                VisualTransformation.None
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = when {
                    isEmail -> KeyboardType.Email
                    isSecure -> KeyboardType.Password
                    else -> KeyboardType.Text
                },
                imeAction = imeAction,
            ),
            trailingIcon = if (isSecure) {
                {
                    IconButton(onClick = { showPassword = !showPassword }) {
                        Icon(
                            imageVector = if (showPassword) {
                                Icons.Outlined.Visibility
                            } else {
                                Icons.Filled.VisibilityOff
                            },
                            contentDescription = if (showPassword) "Hide password" else "Show password",
                            tint = EmBeColors.Grayscale60,
                        )
                    }
                }
            } else {
                null
            },
            shape = RoundedCornerShape(10.dp),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = EmBeColors.InputFill,
                unfocusedContainerColor = EmBeColors.InputFill,
                disabledContainerColor = EmBeColors.InputFill,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
                cursorColor = EmBeColors.BrandOrange,
            ),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

/** Divider with centred caption, used by the social sign-in rows. */
@Composable
fun LabeledDivider(text: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        HorizontalDivider(modifier = Modifier.weight(1f), color = EmBeColors.CardBorder)
        Text(text = text, color = EmBeColors.Grayscale70, fontSize = 13.sp)
        HorizontalDivider(modifier = Modifier.weight(1f), color = EmBeColors.CardBorder)
    }
}
