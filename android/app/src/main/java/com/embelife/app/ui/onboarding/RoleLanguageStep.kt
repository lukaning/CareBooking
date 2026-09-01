package com.embelife.app.ui.onboarding

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.R
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import com.embelife.app.viewmodel.UserRole

private val Languages = listOf("English", "Spanish", "Chinese", "French")
private val UnselectedBorder = Color(0xFFE2E2E6)
private val RoleSubtitleColor = Color(0xFF898989)

/** Port of `RoleLanguageStep`. */
@Composable
fun RoleLanguageStep(
    appViewModel: AppViewModel,
    onContinue: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Text(
                text = "Do you need help or can you provide services?",
                color = EmBeColors.DarkText,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(top = 20.dp),
            )

            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = "Select Your Preferred Language",
                        color = EmBeColors.DarkText,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Icon(
                        imageVector = Icons.Filled.Info,
                        contentDescription = null,
                        tint = EmBeColors.Grayscale60,
                        modifier = Modifier.size(18.dp),
                    )
                }

                LanguageDropdown(
                    selected = appViewModel.preferredLanguage,
                    onSelect = { appViewModel.preferredLanguage = it },
                )
            }

            RoleCard(
                title = "I'm looking for help or support",
                subtitle = "Those are usually the Individuals who need help",
                imageRes = R.drawable.role_client,
                selectedImageRes = R.drawable.role_client_selected,
                isSelected = appViewModel.selectedRole == UserRole.Client,
                onClick = { appViewModel.selectedRole = UserRole.Client },
            )

            RoleCard(
                title = "I'm a Provider",
                subtitle = "Those are usually professionals",
                imageRes = R.drawable.role_provider,
                selectedImageRes = R.drawable.role_provider_selected,
                isSelected = appViewModel.selectedRole == UserRole.Provider,
                onClick = { appViewModel.selectedRole = UserRole.Provider },
            )
        }

        OnboardingBottomBar(
            title = "Get Started",
            enabled = appViewModel.selectedRole != null,
            onClick = onContinue,
        )
    }
}

@Composable
private fun LanguageDropdown(
    selected: String,
    onSelect: (String) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(Color(0xFFFCFCFC))
                .border(2.dp, Color(0xFFEFEFEF), RoundedCornerShape(16.dp))
                .clickable { expanded = true }
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = selected,
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(modifier = Modifier.weight(1f))
            Icon(
                imageVector = Icons.Filled.ExpandMore,
                contentDescription = null,
                tint = EmBeColors.Grayscale60,
            )
        }

        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            Languages.forEach { language ->
                DropdownMenuItem(
                    text = { Text(language) },
                    onClick = {
                        onSelect(language)
                        expanded = false
                    },
                )
            }
        }
    }
}

@Composable
private fun RoleCard(
    title: String,
    subtitle: String,
    imageRes: Int,
    selectedImageRes: Int,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White)
            .border(
                width = if (isSelected) 3.dp else 1.dp,
                color = if (isSelected) EmBeColors.BrandOrange else UnselectedBorder,
                shape = RoundedCornerShape(16.dp),
            )
            .clickable(onClick = onClick)
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Image(
            painter = painterResource(if (isSelected) selectedImageRes else imageRes),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier.size(40.dp),
        )

        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                text = title,
                color = EmBeColors.DarkText,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = subtitle,
                color = RoleSubtitleColor,
                fontSize = 15.sp,
            )
        }
    }
}
