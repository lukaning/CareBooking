package com.embelife.app.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.focus.FocusRequester
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

private const val CODE_LENGTH = 4

/** Port of `EnterCodeView`. */
@Composable
fun EnterCodeScreen(
    appViewModel: AppViewModel,
    email: String,
    name: String,
    onBack: () -> Unit,
) {
    var code by remember { mutableStateOf("") }
    var showTerms by remember { mutableStateOf(false) }
    val focusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current

    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    val codeComplete = code.length == CODE_LENGTH

    Box {
        PlainAuthScreen(onBack = onBack) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp),
                verticalArrangement = Arrangement.spacedBy(28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Column(
                    modifier = Modifier.padding(top = 36.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        text = "Enter Code",
                        color = EmBeColors.DarkText,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text = "We have just sent you 4 digit code via your email $email",
                        color = EmBeColors.Grayscale70,
                        fontSize = 15.sp,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 12.dp),
                    )
                }

                // The hidden field mirrors the iOS approach of layering a nearly
                // transparent TextField over the drawn boxes.
                Box(modifier = Modifier.padding(top = 8.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        repeat(CODE_LENGTH) { index ->
                            CodeBox(
                                filled = index < code.length,
                                isFocused = index == code.length.coerceAtMost(CODE_LENGTH - 1),
                            )
                        }
                    }

                    BasicTextField(
                        value = code,
                        onValueChange = { raw ->
                            code = raw.filter { it.isDigit() }.take(CODE_LENGTH)
                            if (code.length == CODE_LENGTH) keyboard?.hide()
                        },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                        modifier = Modifier
                            .matchParentSize()
                            .alpha(0f)
                            .focusRequester(focusRequester),
                    )
                }

                PrimaryOrangeButton(
                    text = "Create An Account",
                    enabled = codeComplete,
                    modifier = Modifier.padding(top = 12.dp),
                ) {
                    showTerms = true
                }

                Row {
                    Text(
                        text = "Didn't receive code? ",
                        color = EmBeColors.Grayscale70,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        text = "Resend Code",
                        color = EmBeColors.LinkBlue,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable {
                            code = ""
                            focusRequester.requestFocus()
                        },
                    )
                }
            }
        }

        if (showTerms) {
            TermsAgreementOverlay(
                onDisagree = { showTerms = false },
                onAgree = {
                    showTerms = false
                    appViewModel.completeSignUp(name = name, email = email)
                },
            )
        }
    }
}

@Composable
private fun CodeBox(filled: Boolean, isFocused: Boolean) {
    Box(
        modifier = Modifier
            .size(64.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(EmBeColors.InputFill)
            .then(
                if (isFocused) {
                    Modifier.border(1.5.dp, EmBeColors.LinkBlue, RoundedCornerShape(12.dp))
                } else {
                    Modifier
                },
            ),
        contentAlignment = Alignment.Center,
    ) {
        if (filled) {
            Text(
                text = "•",
                color = EmBeColors.DarkText,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}
