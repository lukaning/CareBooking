package com.embelife.app.ui.auth

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.embelife.app.viewmodel.AppViewModel
import java.net.URLDecoder
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

private object AuthRoutes {
    const val SIGN_IN = "signIn"
    const val SIGN_UP = "signUp"
    const val ENTER_CODE = "enterCode/{email}/{name}"
    const val FORGOT_PASSWORD = "forgotPassword"
    const val CREATE_NEW_PASSWORD = "createNewPassword"

    fun enterCode(email: String, name: String): String =
        "enterCode/${email.urlEncoded()}/${name.urlEncoded()}"
}

private fun String.urlEncoded(): String = URLEncoder.encode(this, StandardCharsets.UTF_8.name())

private fun String.urlDecoded(): String = URLDecoder.decode(this, StandardCharsets.UTF_8.name())

/** Port of `AuthFlowView` — `NavigationStack` becomes a `NavHost`. */
@Composable
fun AuthFlowScreen(appViewModel: AppViewModel) {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = AuthRoutes.SIGN_IN) {
        composable(AuthRoutes.SIGN_IN) {
            SignInScreen(
                appViewModel = appViewModel,
                onForgotPassword = { navController.navigate(AuthRoutes.FORGOT_PASSWORD) },
                onSignUp = { navController.navigate(AuthRoutes.SIGN_UP) },
            )
        }

        composable(AuthRoutes.SIGN_UP) {
            SignUpScreen(
                onBack = { navController.popBackStack() },
                onContinue = { email, name ->
                    navController.navigate(AuthRoutes.enterCode(email, name))
                },
            )
        }

        composable(
            route = AuthRoutes.ENTER_CODE,
            arguments = listOf(
                navArgument("email") { type = NavType.StringType },
                navArgument("name") { type = NavType.StringType },
            ),
        ) { entry ->
            EnterCodeScreen(
                appViewModel = appViewModel,
                email = entry.arguments?.getString("email")?.urlDecoded().orEmpty(),
                name = entry.arguments?.getString("name")?.urlDecoded().orEmpty(),
                onBack = { navController.popBackStack() },
            )
        }

        composable(AuthRoutes.FORGOT_PASSWORD) {
            ForgotPasswordScreen(
                onBack = { navController.popBackStack() },
                onNext = { navController.navigate(AuthRoutes.CREATE_NEW_PASSWORD) },
            )
        }

        composable(AuthRoutes.CREATE_NEW_PASSWORD) {
            CreateNewPasswordScreen(
                onBack = { navController.popBackStack() },
                onFinished = {
                    navController.popBackStack(route = AuthRoutes.SIGN_IN, inclusive = false)
                },
            )
        }
    }
}
