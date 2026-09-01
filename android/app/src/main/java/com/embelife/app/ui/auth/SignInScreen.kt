package com.embelife.app.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.ui.components.AuthTextField
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel

/** Port of `SignInView`. */
@Composable
fun SignInScreen(
    appViewModel: AppViewModel,
    onForgotPassword: () -> Unit,
    onSignUp: () -> Unit,
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var rememberMe by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
        AuthHeader(
            title = "Sign In",
            headline = "Hi, Welcome Back! 👋",
            subtitle = "Lorem ipsum dolor sit amet, consectetur",
            onBack = { appViewModel.showWelcome() },
            showsBackControl = true,
        )

        AuthFormSheet(topPadding = 52) {
            Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                AuthTextField(
                    title = "Email Address",
                    placeholder = "Enter your email address",
                    value = email,
                    onValueChange = { email = it },
                )

                AuthTextField(
                    title = "Password",
                    placeholder = "Enter your password",
                    value = password,
                    onValueChange = { password = it },
                    isSecure = true,
                    imeAction = ImeAction.Done,
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(
                        modifier = Modifier.clickable { rememberMe = !rememberMe },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(
                            imageVector = if (rememberMe) {
                                Icons.Filled.CheckCircle
                            } else {
                                Icons.Outlined.Circle
                            },
                            contentDescription = null,
                            tint = if (rememberMe) EmBeColors.BrandOrange else EmBeColors.Grayscale60,
                        )
                        Text(
                            text = "Remember Me",
                            color = EmBeColors.Grayscale70,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    Text(
                        text = "Forgot Password",
                        color = EmBeColors.ErrorCoral,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable(onClick = onForgotPassword),
                    )
                }

                PrimaryOrangeButton(
                    text = "Sign In",
                    modifier = Modifier.padding(top = 4.dp),
                ) {
                    appViewModel.completeSignIn(
                        email = email.ifEmpty { "user@example.com" },
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                ) {
                    Text(
                        text = "Don't have an account? ",
                        color = EmBeColors.Grayscale70,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        text = "Sign Up",
                        color = EmBeColors.LinkBlue,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable(onClick = onSignUp),
                    )
                }

                SocialSignInRow(modifier = Modifier.padding(top = 8.dp))

                TermsFooter(modifier = Modifier.padding(top = 8.dp))
            }
        }
    }
}
