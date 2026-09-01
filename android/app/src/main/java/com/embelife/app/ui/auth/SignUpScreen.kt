package com.embelife.app.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.embelife.app.ui.components.AuthTextField
import com.embelife.app.ui.components.PrimaryOrangeButton

/** Port of `SignUpView`. */
@Composable
fun SignUpScreen(
    onBack: () -> Unit,
    onContinue: (email: String, name: String) -> Unit,
) {
    var fullName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
        AuthHeader(
            title = "Sign Up",
            headline = "Create Account",
            subtitle = "Lorem ipsum dolor sit amet, consectetur",
            onBack = onBack,
        )

        AuthFormSheet {
            Column(verticalArrangement = Arrangement.spacedBy(18.dp)) {
                AuthTextField(
                    title = "Full Name",
                    placeholder = "Enter your name",
                    value = fullName,
                    onValueChange = { fullName = it },
                )

                AuthTextField(
                    title = "E-mail",
                    placeholder = "Enter your email",
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

                PrimaryOrangeButton(
                    text = "Create An Account",
                    modifier = Modifier.padding(top = 8.dp),
                ) {
                    onContinue(
                        email.trim().ifEmpty { "example@gmail.com" },
                        fullName.trim().ifEmpty { "Alex" },
                    )
                }

                SocialSignInRow(modifier = Modifier.padding(top = 12.dp))

                TermsFooter()
            }
        }
    }
}
