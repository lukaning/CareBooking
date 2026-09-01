package com.embelife.app.ui.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.ui.components.AuthTextField
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors

/** Port of `ForgotPasswordView`. */
@Composable
fun ForgotPasswordScreen(
    onBack: () -> Unit,
    onNext: () -> Unit,
) {
    var email by remember { mutableStateOf("") }

    PlainAuthScreen(onBack = onBack) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier.padding(top = 36.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = "Forgot Password",
                    color = EmBeColors.DarkText,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = "Recover your account password",
                    color = EmBeColors.Grayscale70,
                    fontSize = 15.sp,
                )
            }

            AuthTextField(
                title = "E-mail",
                placeholder = "Enter your email",
                value = email,
                onValueChange = { email = it },
                imeAction = ImeAction.Done,
                modifier = Modifier.padding(horizontal = 24.dp),
            )

            PrimaryOrangeButton(
                text = "Next",
                modifier = Modifier.padding(horizontal = 24.dp),
                onClick = onNext,
            )
        }
    }
}

/** Port of `CreateNewPasswordView`. */
@Composable
fun CreateNewPasswordScreen(
    onBack: () -> Unit,
    onFinished: () -> Unit,
) {
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var showSuccess by remember { mutableStateOf(false) }

    val canContinue = newPassword.isNotEmpty() && newPassword == confirmPassword

    Box {
        PlainAuthScreen(onBack = onBack) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Column(
                    modifier = Modifier
                        .padding(top = 36.dp)
                        .padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        text = "Create a New Password",
                        color = EmBeColors.DarkText,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    )
                    Text(
                        text = "Enter your new password",
                        color = EmBeColors.Grayscale70,
                        fontSize = 15.sp,
                    )
                }

                Column(
                    modifier = Modifier.padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(18.dp),
                ) {
                    AuthTextField(
                        title = "New Password",
                        placeholder = "Enter new password",
                        value = newPassword,
                        onValueChange = { newPassword = it },
                        isSecure = true,
                    )
                    AuthTextField(
                        title = "Confirm Password",
                        placeholder = "Confirm your password",
                        value = confirmPassword,
                        onValueChange = { confirmPassword = it },
                        isSecure = true,
                        imeAction = ImeAction.Done,
                    )
                }

                PrimaryOrangeButton(
                    text = "Next",
                    enabled = canContinue,
                    modifier = Modifier.padding(horizontal = 24.dp),
                ) {
                    showSuccess = true
                }
            }
        }

        if (showSuccess) {
            PasswordSuccessOverlay {
                showSuccess = false
                onFinished()
            }
        }
    }
}
