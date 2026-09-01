package com.embelife.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import com.embelife.app.ui.RootScreen
import com.embelife.app.ui.theme.EmBeLifeTheme
import com.embelife.app.viewmodel.AppViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            EmBeLifeTheme {
                val appViewModel: AppViewModel = viewModel()
                RootScreen(appViewModel = appViewModel)
            }
        }
    }
}
