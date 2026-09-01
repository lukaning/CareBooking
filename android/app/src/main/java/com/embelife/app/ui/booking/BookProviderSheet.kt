package com.embelife.app.ui.booking

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Face
import androidx.compose.material.icons.filled.ListAlt
import androidx.compose.material.icons.filled.Outbox
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.Wallet
import androidx.compose.material3.DatePicker
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.embelife.app.model.BankAccountDetails
import com.embelife.app.model.Booking
import com.embelife.app.model.BookingChecklistTask
import com.embelife.app.model.BookingStatus
import com.embelife.app.model.BookingTaskCatalog
import com.embelife.app.model.BookingTaskOption
import com.embelife.app.model.ContactPaymentDetails
import com.embelife.app.model.CreditCardDetails
import com.embelife.app.model.FamilyMember
import com.embelife.app.model.MemberAvatarStyle
import com.embelife.app.model.PaymentMethodKind
import com.embelife.app.model.Provider
import com.embelife.app.ui.components.PrimaryOrangeButton
import com.embelife.app.ui.home.BookingAppointmentType
import com.embelife.app.ui.theme.EmBeColors
import com.embelife.app.viewmodel.AppViewModel
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlin.math.max
import kotlin.math.roundToInt

private val SoftBorder = Color(0xFFE6E8EE)
private val SelectedChipFill = Color(0xFFE0EDFF)
private val PaymentSelectedFill = Color(0xFFFFD8CB)
private val RadioRing = Color(0xFFB2B8C2)
private val FieldLabel = Color(0xFF1A3373)
private val ChecklistBG = Color(0xFFF0EDFA)
private val ConfirmedChecklistBG = Color(0xFFE6F5EB)
private val CheckGreen = Color(0xFF33B366)
private val LinkBlue = EmBeColors.LinkBlue

private val Durations = listOf(15, 30, 45, 60, 75, 90, 120)
private val GiftBalance = 240

private val WideDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("MMMM d, yyyy")
private val ServiceDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("d MMM, yyyy")
private val TimeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a")

private enum class BookStep {
    Schedule, Who, SelectCategory, TaskDetail, Payment, Summary, Requested
}

private enum class ScheduleField { Date, Start, Duration }

/**
 * Multi-step booking: schedule → who → select category → task detail → payment → summary → requested.
 * Port of `BookProviderSheet`.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookProviderSheet(
    provider: Provider,
    appointmentType: BookingAppointmentType,
    appViewModel: AppViewModel,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var step by remember { mutableStateOf(BookStep.Schedule) }
    var selectedField by remember { mutableStateOf(ScheduleField.Date) }

    var selectedDate by remember { mutableStateOf(LocalDate.now()) }
    var startTime by remember { mutableStateOf(LocalTime.of(12, 30)) }
    var durationMinutes by remember { mutableIntStateOf(30) }

    var selectedMemberIDs by remember { mutableStateOf(setOf<UUID>()) }
    var expandedMemberID by remember { mutableStateOf<UUID?>(null) }
    var isAddingMember by remember { mutableStateOf(false) }
    var newMemberFirst by remember { mutableStateOf("") }
    var newMemberLast by remember { mutableStateOf("") }
    var draftMembers by remember { mutableStateOf(emptyList<FamilyMember>()) }

    var selectedCategoryIDs by remember { mutableStateOf(setOf<String>()) }
    var selectedChecklistIDs by remember { mutableStateOf(setOf<UUID>()) }
    var workingSuggestedTasks by remember { mutableStateOf(emptyList<BookingChecklistTask>()) }
    var bookingTasks by remember { mutableStateOf(emptyList<BookingChecklistTask>()) }
    var taskDescriptionDetail by remember { mutableStateOf("") }
    var estimatedTimeLabel by remember { mutableStateOf("30 min") }
    var showTaskValidation by remember { mutableStateOf(false) }
    var checklistExpanded by remember { mutableStateOf(true) }
    var showEstimatedTimePicker by remember { mutableStateOf(false) }
    var showAddSubtaskComposer by remember { mutableStateOf(false) }
    var composerSubtasks by remember { mutableStateOf(emptyList<BookingChecklistTask>()) }

    var selectedPayment by remember { mutableStateOf(PaymentMethodKind.CreditCard) }
    var bankDetails by remember { mutableStateOf(BankAccountDetails.sample) }
    var zelleDetails by remember { mutableStateOf(ContactPaymentDetails.zelleSample) }
    var venmoDetails by remember { mutableStateOf(ContactPaymentDetails.venmoSample) }
    var paypalDetails by remember { mutableStateOf(ContactPaymentDetails.paypalSample) }
    var creditCardDetails by remember { mutableStateOf(CreditCardDetails.sample) }

    LaunchedEffect(Unit) {
        if (draftMembers.isEmpty()) {
            draftMembers = appViewModel.profile.familyMembers.ifEmpty { FamilyMember.samples }
        }
        if (selectedMemberIDs.isEmpty()) {
            draftMembers.firstOrNull()?.let {
                selectedMemberIDs = setOf(it.id)
                expandedMemberID = it.id
            }
        }
    }

    val availableMembers = draftMembers.ifEmpty {
        appViewModel.profile.familyMembers.ifEmpty { FamilyMember.samples }
    }
    val selectedMembers = availableMembers.filter { selectedMemberIDs.contains(it.id) }
    val recipientLabel = selectedMembers.map { it.displayName }.ifEmpty { listOf("—") }.joinToString(", ")
    val estimatedTotal = run {
        val hours = max(durationMinutes / 60.0, 0.25)
        (provider.ratePerHour * hours).roundToInt()
    }
    val selectedCategoryOptions = BookingTaskCatalog.allOptions.filter { selectedCategoryIDs.contains(it.id) }

    val paymentMethodLabel = when (selectedPayment) {
        PaymentMethodKind.BankAccount -> "Bank account"
        PaymentMethodKind.Zelle -> "Zelle"
        PaymentMethodKind.Venmo -> "Venmo"
        PaymentMethodKind.Paypal -> "PayPal"
        PaymentMethodKind.GiftFund -> "Gift Fund"
        PaymentMethodKind.CreditCard -> {
            val last = creditCardDetails.cardNumber.filter { it.isDigit() }.takeLast(4)
            if (last.isEmpty()) "Credit card" else "Credit card · $last"
        }
    }

    val paymentReady = when (selectedPayment) {
        PaymentMethodKind.BankAccount ->
            bankDetails.accountHolderName.isNotEmpty() &&
                bankDetails.accountNumber.isNotEmpty() &&
                bankDetails.abaRoutingNumber.isNotEmpty()
        PaymentMethodKind.Zelle -> zelleDetails.contact.isNotEmpty()
        PaymentMethodKind.Venmo -> venmoDetails.contact.isNotEmpty()
        PaymentMethodKind.Paypal -> paypalDetails.contact.isNotEmpty()
        PaymentMethodKind.GiftFund -> GiftBalance > 0
        PaymentMethodKind.CreditCard ->
            creditCardDetails.cardNumber.isNotEmpty() &&
                creditCardDetails.expiry.isNotEmpty() &&
                creditCardDetails.cvc.isNotEmpty()
    }

    fun rebuildSuggestedTasks(selectAllIfEmpty: Boolean = false) {
        val previouslyCheckedTitles = workingSuggestedTasks
            .filter { selectedChecklistIDs.contains(it.id) }
            .map { it.title }
            .toSet()
        workingSuggestedTasks = BookingTaskCatalog.suggestedChecklist(selectedCategoryOptions)
        selectedChecklistIDs = if (previouslyCheckedTitles.isEmpty() && selectAllIfEmpty) {
            workingSuggestedTasks.map { it.id }.toSet()
        } else {
            workingSuggestedTasks.filter { previouslyCheckedTitles.contains(it.title) }.map { it.id }.toSet()
        }
    }

    fun attachComposerSubtasks() {
        if (composerSubtasks.isEmpty() || bookingTasks.isEmpty()) return
        bookingTasks = bookingTasks.toMutableList().also { list ->
            list[0] = list[0].copy(subtasks = composerSubtasks)
        }
    }

    fun ensureComposerTaskIfNeeded() {
        if (bookingTasks.isEmpty()) {
            val trimmed = taskDescriptionDetail.trim()
            val title = trimmed.ifEmpty { composerSubtasks.firstOrNull()?.title } ?: return
            if (title.isEmpty()) return
            val option = selectedCategoryOptions.firstOrNull()
            bookingTasks = listOf(
                BookingChecklistTask(
                    title = title,
                    category = option?.categoryTitle ?: "Custom task",
                    subcategory = option?.title ?: title,
                    detailDescription = trimmed,
                    estimatedMinutes = BookingChecklistTask.minutesFromEstimateLabel(estimatedTimeLabel),
                ),
            )
        }
        attachComposerSubtasks()
    }

    fun goBack() {
        showTaskValidation = false
        step = when (step) {
            BookStep.Who -> BookStep.Schedule
            BookStep.SelectCategory -> BookStep.Who
            BookStep.TaskDetail -> BookStep.SelectCategory
            BookStep.Payment -> BookStep.TaskDetail
            BookStep.Summary -> BookStep.Payment
            else -> step
        }
    }

    fun submitBookingRequest() {
        attachComposerSubtasks()
        val combinedStart = LocalDateTime.of(selectedDate, startTime)
        val primaryTitle = bookingTasks.firstOrNull()?.title
            ?: "${provider.title} with ${provider.name}"
        val descriptionText = bookingTasks.firstOrNull()?.detailDescription?.takeIf { it.isNotEmpty() }
            ?: "${appointmentType.title} · $durationMinutes min · $$estimatedTotal · $paymentMethodLabel"
        val booking = Booking(
            provider = provider,
            date = selectedDate,
            startTime = combinedStart,
            durationMinutes = durationMinutes,
            status = BookingStatus.Requested,
            serviceProvidedTo = recipientLabel,
            title = primaryTitle,
            taskDescription = descriptionText,
            location = appViewModel.profile.address.ifEmpty { "Service location TBD" },
            checklistTasks = bookingTasks.ifEmpty { Booking.defaultChecklist() },
        )
        appViewModel.addBooking(booking)
        step = BookStep.Requested
    }

    fun goForward() {
        when (step) {
            BookStep.Schedule -> step = BookStep.Who
            BookStep.Who -> {
                if (selectedMemberIDs.isEmpty()) {
                    isAddingMember = true
                    return
                }
                step = BookStep.SelectCategory
            }
            BookStep.SelectCategory -> {
                if (selectedCategoryIDs.isEmpty()) {
                    showTaskValidation = true
                    return
                }
                if (bookingTasks.isEmpty()) rebuildSuggestedTasks(selectAllIfEmpty = true)
                showTaskValidation = false
                step = BookStep.TaskDetail
            }
            BookStep.TaskDetail -> {
                ensureComposerTaskIfNeeded()
                if (bookingTasks.isEmpty()) {
                    showTaskValidation = true
                    return
                }
                showTaskValidation = false
                step = BookStep.Payment
            }
            BookStep.Payment -> {
                if (!paymentReady) return
                step = BookStep.Summary
            }
            BookStep.Summary -> submitBookingRequest()
            BookStep.Requested -> Unit
        }
    }

    val overlaySteps = step == BookStep.Summary || step == BookStep.Requested

    ModalBottomSheet(
        onDismissRequest = {
            if (step != BookStep.Summary) onDismiss()
        },
        sheetState = sheetState,
        containerColor = if (overlaySteps) Color.Transparent else Color.White,
        dragHandle = if (overlaySteps) {
            null
        } else {
            { androidx.compose.material3.BottomSheetDefaults.DragHandle() }
        },
        shape = if (overlaySteps) RoundedCornerShape(0.dp) else RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.95f)
                .navigationBarsPadding(),
        ) {
            when (step) {
                BookStep.Summary -> SummaryStep(
                    provider = provider,
                    selectedDate = selectedDate,
                    startTime = startTime,
                    durationMinutes = durationMinutes,
                    recipientLabel = recipientLabel,
                    estimatedTotal = estimatedTotal,
                    paymentLabel = selectedPayment.summaryLabel,
                    onEdit = { goBack() },
                    onRequest = { goForward() },
                )

                BookStep.Requested -> RequestedStep(onDismiss = onDismiss)

                else -> Column(modifier = Modifier.fillMaxSize()) {
                    BookSheetToolbar(
                        step = step,
                        onBack = { goBack() },
                        onClose = onDismiss,
                    )
                    BookSheetHeader(step = step, providerName = provider.name)

                    when (step) {
                        BookStep.Schedule -> ScheduleStep(
                            selectedField = selectedField,
                            onSelectField = { selectedField = it },
                            selectedDate = selectedDate,
                            onDateChange = { selectedDate = it },
                            startTime = startTime,
                            onStartTimeChange = { startTime = it },
                            durationMinutes = durationMinutes,
                            onDurationChange = { durationMinutes = it },
                            onNext = { goForward() },
                        )

                        BookStep.Who -> WhoStep(
                            members = availableMembers,
                            selectedMemberIDs = selectedMemberIDs,
                            expandedMemberID = expandedMemberID,
                            isAddingMember = isAddingMember,
                            newMemberFirst = newMemberFirst,
                            newMemberLast = newMemberLast,
                            onToggleMember = { id ->
                                selectedMemberIDs = if (selectedMemberIDs.contains(id)) {
                                    selectedMemberIDs - id
                                } else {
                                    selectedMemberIDs + id
                                }
                            },
                            onExpandMember = { id ->
                                expandedMemberID = if (expandedMemberID == id) null else id
                                if (!selectedMemberIDs.contains(id)) {
                                    selectedMemberIDs = selectedMemberIDs + id
                                }
                            },
                            onStartAdd = { isAddingMember = true },
                            onCancelAdd = {
                                isAddingMember = false
                                newMemberFirst = ""
                                newMemberLast = ""
                            },
                            onFirstChange = { newMemberFirst = it },
                            onLastChange = { newMemberLast = it },
                            onConfirmAdd = {
                                val member = FamilyMember(
                                    firstName = newMemberFirst.trim(),
                                    lastName = newMemberLast.trim(),
                                    preferredServices = listOf("Personal care/ hygiene"),
                                    preferredTimes = listOf("8am – 10am"),
                                    avatarStyle = MemberAvatarStyle.next(after = draftMembers.size),
                                )
                                draftMembers = draftMembers + member
                                selectedMemberIDs = selectedMemberIDs + member.id
                                expandedMemberID = member.id
                                isAddingMember = false
                                newMemberFirst = ""
                                newMemberLast = ""
                                appViewModel.profile = appViewModel.profile.copy(familyMembers = draftMembers)
                            },
                            onContinue = { goForward() },
                            onBack = { goBack() },
                        )

                        BookStep.SelectCategory -> SelectCategoryStep(
                            selectedCategoryIDs = selectedCategoryIDs,
                            showValidation = showTaskValidation,
                            onToggle = { option ->
                                selectedCategoryIDs = if (selectedCategoryIDs.contains(option.id)) {
                                    selectedCategoryIDs - option.id
                                } else {
                                    selectedCategoryIDs + option.id
                                }
                                bookingTasks = emptyList()
                                selectedChecklistIDs = emptySet()
                                workingSuggestedTasks = emptyList()
                                showTaskValidation = false
                            },
                            onNext = { goForward() },
                            onBack = { goBack() },
                        )

                        BookStep.TaskDetail -> TaskDetailStep(
                            selectedCategoryOptions = selectedCategoryOptions,
                            workingSuggestedTasks = workingSuggestedTasks,
                            selectedChecklistIDs = selectedChecklistIDs,
                            bookingTasks = bookingTasks,
                            checklistExpanded = checklistExpanded,
                            taskDescriptionDetail = taskDescriptionDetail,
                            estimatedTimeLabel = estimatedTimeLabel,
                            composerSubtasks = composerSubtasks,
                            showValidation = showTaskValidation,
                            onRemoveCategory = { optionId ->
                                selectedCategoryIDs = selectedCategoryIDs - optionId
                                bookingTasks = emptyList()
                                rebuildSuggestedTasks(selectAllIfEmpty = true)
                            },
                            onToggleChecklistExpanded = { checklistExpanded = !checklistExpanded },
                            onToggleSuggested = { id ->
                                selectedChecklistIDs = if (selectedChecklistIDs.contains(id)) {
                                    selectedChecklistIDs - id
                                } else {
                                    selectedChecklistIDs + id
                                }
                                showTaskValidation = false
                            },
                            onConfirmChecklist = {
                                val chosen = workingSuggestedTasks.filter { selectedChecklistIDs.contains(it.id) }
                                if (chosen.isEmpty()) {
                                    showTaskValidation = true
                                    return@TaskDetailStep
                                }
                                bookingTasks = chosen.map { task ->
                                    if (taskDescriptionDetail.isNotEmpty()) {
                                        task.copy(detailDescription = taskDescriptionDetail)
                                    } else {
                                        task
                                    }
                                }
                                attachComposerSubtasks()
                                checklistExpanded = true
                                showTaskValidation = false
                            },
                            onEditTasks = {
                                val confirmedTitles = bookingTasks.map { it.title }.toSet()
                                workingSuggestedTasks = BookingTaskCatalog.suggestedChecklist(selectedCategoryOptions)
                                selectedChecklistIDs = workingSuggestedTasks
                                    .filter { confirmedTitles.contains(it.title) }
                                    .map { it.id }
                                    .toSet()
                                    .ifEmpty { workingSuggestedTasks.map { it.id }.toSet() }
                                bookingTasks = emptyList()
                            },
                            onRemoveTask = { id ->
                                bookingTasks = bookingTasks.filterNot { it.id == id }
                                if (bookingTasks.isEmpty()) rebuildSuggestedTasks(selectAllIfEmpty = true)
                            },
                            onDescriptionChange = { taskDescriptionDetail = it },
                            onPickEstimatedTime = { showEstimatedTimePicker = true },
                            onAddSubtask = { showAddSubtaskComposer = true },
                            onContinue = { goForward() },
                            onBack = { goBack() },
                        )

                        BookStep.Payment -> PaymentStep(
                            selectedPayment = selectedPayment,
                            bankDetails = bankDetails,
                            zelleDetails = zelleDetails,
                            venmoDetails = venmoDetails,
                            paypalDetails = paypalDetails,
                            creditCardDetails = creditCardDetails,
                            paymentReady = paymentReady,
                            onSelect = { selectedPayment = it },
                            onBankChange = { bankDetails = it },
                            onZelleChange = { zelleDetails = it },
                            onVenmoChange = { venmoDetails = it },
                            onPaypalChange = { paypalDetails = it },
                            onCardChange = { creditCardDetails = it },
                            onContinue = { goForward() },
                            onBack = { goBack() },
                        )

                        else -> Unit
                    }
                }
            }
        }
    }

    if (showEstimatedTimePicker) {
        EstimatedTimePickerSheet(
            selectedLabel = estimatedTimeLabel,
            onSelect = {
                estimatedTimeLabel = it
                showEstimatedTimePicker = false
            },
            onDismiss = { showEstimatedTimePicker = false },
        )
    }

    if (showAddSubtaskComposer) {
        AddSubTaskComposerSheet(
            onCancel = { showAddSubtaskComposer = false },
            onSave = { task ->
                composerSubtasks = composerSubtasks + task
                showAddSubtaskComposer = false
            },
        )
    }
}

@Composable
private fun BookSheetToolbar(step: BookStep, onBack: () -> Unit, onClose: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (step != BookStep.Schedule) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = "Back",
                tint = EmBeColors.DarkText,
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFE8E9ED))
                    .clickable(onClick = onBack)
                    .padding(4.dp),
            )
        } else {
            Spacer(modifier = Modifier.size(32.dp))
        }
        Spacer(modifier = Modifier.weight(1f))
        Icon(
            imageVector = Icons.Filled.Close,
            contentDescription = "Close",
            tint = EmBeColors.DarkText,
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(Color(0xFFE8E9ED))
                .clickable(onClick = onClose)
                .padding(6.dp),
        )
    }
}

@Composable
private fun BookSheetHeader(step: BookStep, providerName: String) {
    val title = when (step) {
        BookStep.Schedule, BookStep.Who -> "Book a Provider"
        BookStep.SelectCategory -> "Select category"
        BookStep.TaskDetail -> "Detail"
        BookStep.Payment -> "Set up payment"
        else -> "Booking details"
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp, bottom = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(22.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(EmBeColors.BrandOrange),
        )
        Column {
            Text(text = title, color = EmBeColors.DarkText, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            if (step == BookStep.Schedule || step == BookStep.Who) {
                Text(text = providerName, color = EmBeColors.MutedText, fontSize = 14.sp)
            }
        }
    }
}

@Composable
private fun StepFooter(
    primaryTitle: String,
    primaryEnabled: Boolean = true,
    showBack: Boolean = true,
    validationMessage: String? = null,
    showValidation: Boolean = false,
    onPrimary: () -> Unit,
    onBack: (() -> Unit)? = null,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(bottom = 20.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (showValidation && validationMessage != null) {
            Text(
                text = validationMessage,
                color = EmBeColors.ErrorCoral,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
        PrimaryOrangeButton(
            text = primaryTitle,
            enabled = primaryEnabled,
            onClick = onPrimary,
        )
        if (showBack && onBack != null) {
            Text(
                text = "Back",
                color = EmBeColors.MutedText,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onBack)
                    .padding(vertical = 8.dp),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ScheduleStep(
    selectedField: ScheduleField,
    onSelectField: (ScheduleField) -> Unit,
    selectedDate: LocalDate,
    onDateChange: (LocalDate) -> Unit,
    startTime: LocalTime,
    onStartTimeChange: (LocalTime) -> Unit,
    durationMinutes: Int,
    onDurationChange: (Int) -> Unit,
    onNext: () -> Unit,
) {
    val zone = ZoneId.systemDefault()
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = selectedDate.atStartOfDay(zone).toInstant().toEpochMilli(),
    )
    LaunchedEffect(datePickerState.selectedDateMillis) {
        datePickerState.selectedDateMillis?.let { millis ->
            val date = Instant.ofEpochMilli(millis).atZone(zone).toLocalDate()
            if (date != selectedDate) onDateChange(date)
        }
    }
    val timePickerState = rememberTimePickerState(
        initialHour = startTime.hour,
        initialMinute = startTime.minute,
        is24Hour = false,
    )
    LaunchedEffect(timePickerState.hour, timePickerState.minute) {
        val next = LocalTime.of(timePickerState.hour, timePickerState.minute)
        if (next != startTime) onStartTimeChange(next)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = "Choose a day and time you want to schedule",
                color = EmBeColors.MutedText,
                fontSize = 14.sp,
                modifier = Modifier.padding(horizontal = 20.dp),
            )

            Column(
                modifier = Modifier.padding(horizontal = 20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                SelectionCard(
                    isActive = selectedField == ScheduleField.Date,
                    onClick = { onSelectField(ScheduleField.Date) },
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.CalendarToday, contentDescription = null, tint = LinkBlue)
                        Column {
                            Text("Date", color = EmBeColors.MutedText, fontSize = 12.sp)
                            Text(
                                selectedDate.format(WideDateFormatter),
                                color = EmBeColors.DarkText,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                        }
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    SelectionCard(
                        isActive = selectedField == ScheduleField.Start,
                        onClick = { onSelectField(ScheduleField.Start) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Schedule, contentDescription = null, tint = EmBeColors.Grayscale70)
                            Column {
                                Text("Start Time", color = EmBeColors.MutedText, fontSize = 12.sp)
                                Text(
                                    startTime.format(TimeFormatter),
                                    color = EmBeColors.DarkText,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.SemiBold,
                                )
                            }
                        }
                    }
                    SelectionCard(
                        isActive = selectedField == ScheduleField.Duration,
                        onClick = { onSelectField(ScheduleField.Duration) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Schedule, contentDescription = null, tint = EmBeColors.Grayscale70)
                            Column {
                                Text("Duration", color = EmBeColors.MutedText, fontSize = 12.sp)
                                Text(
                                    "$durationMinutes min",
                                    color = EmBeColors.DarkText,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.SemiBold,
                                )
                            }
                        }
                    }
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 320.dp)
                    .padding(horizontal = 12.dp),
            ) {
                when (selectedField) {
                    ScheduleField.Date -> {
                        DatePicker(
                            state = datePickerState,
                            title = null,
                            headline = null,
                            showModeToggle = false,
                        )
                    }
                    ScheduleField.Start -> {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center,
                        ) {
                            TimePicker(state = timePickerState)
                        }
                    }
                    ScheduleField.Duration -> {
                        DurationList(
                            durationMinutes = durationMinutes,
                            onDurationChange = onDurationChange,
                        )
                    }
                }
            }
        }
        StepFooter(primaryTitle = "Next Step", showBack = false, onPrimary = onNext)
    }
}

@Composable
private fun DurationList(durationMinutes: Int, onDurationChange: (Int) -> Unit) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text("$durationMinutes min", color = EmBeColors.DarkText, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            Text(
                text = "Clear",
                color = LinkBlue,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { onDurationChange(30) },
            )
        }
        Durations.forEach { minutes ->
            Text(
                text = "$minutes min",
                color = EmBeColors.DarkText,
                fontSize = 16.sp,
                fontWeight = if (durationMinutes == minutes) FontWeight.SemiBold else FontWeight.Normal,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (durationMinutes == minutes) Color(0xFFF0F2F5) else Color.Transparent)
                    .clickable { onDurationChange(minutes) }
                    .padding(horizontal = 16.dp, vertical = 14.dp),
            )
        }
    }
}

@Composable
private fun SelectionCard(
    isActive: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .border(if (isActive) 2.dp else 1.dp, if (isActive) LinkBlue else SoftBorder, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
            .padding(14.dp),
    ) {
        content()
    }
}

@Composable
private fun WhoStep(
    members: List<FamilyMember>,
    selectedMemberIDs: Set<UUID>,
    expandedMemberID: UUID?,
    isAddingMember: Boolean,
    newMemberFirst: String,
    newMemberLast: String,
    onToggleMember: (UUID) -> Unit,
    onExpandMember: (UUID) -> Unit,
    onStartAdd: () -> Unit,
    onCancelAdd: () -> Unit,
    onFirstChange: (String) -> Unit,
    onLastChange: (String) -> Unit,
    onConfirmAdd: () -> Unit,
    onContinue: () -> Unit,
    onBack: () -> Unit,
) {
    val canAdd = newMemberFirst.trim().isNotEmpty() && newMemberLast.trim().isNotEmpty()
    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = "Who will you book for",
                color = Color(0xFF2E384F),
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
            )
            Text(text = "Member List", color = EmBeColors.MutedText, fontSize = 14.sp, fontWeight = FontWeight.Medium)

            members.forEach { member ->
                MemberRow(
                    member = member,
                    selected = selectedMemberIDs.contains(member.id),
                    expanded = expandedMemberID == member.id,
                    onToggle = { onToggleMember(member.id) },
                    onExpand = { onExpandMember(member.id) },
                )
            }

            if (isAddingMember) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color(0xFFF7F8FB))
                        .padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text("Add family or friend", color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        OutlinedTextField(
                            value = newMemberFirst,
                            onValueChange = onFirstChange,
                            placeholder = { Text("First name") },
                            singleLine = true,
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                        )
                        OutlinedTextField(
                            value = newMemberLast,
                            onValueChange = onLastChange,
                            placeholder = { Text("Last name") },
                            singleLine = true,
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                        )
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "Cancel",
                            color = EmBeColors.MutedText,
                            modifier = Modifier.clickable(onClick = onCancelAdd),
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Text(
                            text = "Add",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            modifier = Modifier
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (canAdd) EmBeColors.BrandOrange else EmBeColors.Grayscale60)
                                .clickable(enabled = canAdd, onClick = onConfirmAdd)
                                .padding(horizontal = 16.dp, vertical = 10.dp),
                        )
                    }
                }
            } else {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(onClick = onStartAdd),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .border(1.5.dp, SoftBorder, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("+", color = EmBeColors.MutedText, fontSize = 20.sp)
                    }
                    Text("Adding member", color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }
        StepFooter(
            primaryTitle = "Continue",
            primaryEnabled = selectedMemberIDs.isNotEmpty(),
            onPrimary = onContinue,
            onBack = onBack,
        )
    }
}

@Composable
private fun MemberRow(
    member: FamilyMember,
    selected: Boolean,
    expanded: Boolean,
    onToggle: () -> Unit,
    onExpand: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = if (selected) Icons.Filled.CheckBox else Icons.Filled.CheckBoxOutlineBlank,
                contentDescription = null,
                tint = if (selected) CheckGreen else LinkBlue.copy(alpha = 0.55f),
                modifier = Modifier
                    .size(28.dp)
                    .clickable(onClick = onToggle),
            )
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(member.avatarStyle.color),
                contentAlignment = Alignment.Center,
            ) {
                Text(member.monogram, color = Color.White, fontWeight = FontWeight.SemiBold)
            }
            Row(
                modifier = Modifier
                    .weight(1f)
                    .clickable(onClick = onExpand),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(member.displayName, color = EmBeColors.DarkText, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                Icon(
                    imageVector = if (expanded) Icons.Filled.ExpandMore else Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = EmBeColors.MutedText,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
        if (expanded) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.White)
                    .padding(12.dp),
            ) {
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Preferred Service", color = EmBeColors.MutedText, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    if (member.preferredServices.isEmpty()) {
                        Text("—", color = EmBeColors.MutedText)
                    } else {
                        member.preferredServices.forEach {
                            Text(it, color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
                Box(
                    modifier = Modifier
                        .padding(horizontal = 10.dp)
                        .width(1.dp)
                        .height(60.dp)
                        .background(SoftBorder),
                )
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Preferred time", color = EmBeColors.MutedText, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    if (member.preferredTimes.isEmpty()) {
                        Text("—", color = EmBeColors.MutedText)
                    } else {
                        member.preferredTimes.forEach {
                            Text(it, color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SelectCategoryStep(
    selectedCategoryIDs: Set<String>,
    showValidation: Boolean,
    onToggle: (BookingTaskOption) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Text(
                text = "Choose at least one care task category for this visit",
                color = EmBeColors.MutedText,
                fontSize = 14.sp,
            )
            BookingTaskCatalog.groups.forEach { group ->
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.AutoMirrored.Filled.ListAlt, contentDescription = null, tint = EmBeColors.MutedText, modifier = Modifier.size(16.dp))
                        Text(group.title, color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    }
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        group.options.forEach { option ->
                            val selected = selectedCategoryIDs.contains(option.id)
                            Row(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(if (selected) SelectedChipFill else Color.White)
                                    .border(
                                        1.dp,
                                        if (selected) LinkBlue.copy(alpha = 0.45f) else SoftBorder,
                                        RoundedCornerShape(12.dp),
                                    )
                                    .clickable { onToggle(option) }
                                    .padding(horizontal = 12.dp, vertical = 10.dp),
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                if (selected) {
                                    Icon(Icons.Filled.Check, contentDescription = null, tint = LinkBlue, modifier = Modifier.size(14.dp))
                                }
                                Text(
                                    text = option.title,
                                    color = if (selected) Color(0xFF26408C) else EmBeColors.DarkText,
                                    fontSize = 14.sp,
                                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                                )
                            }
                        }
                    }
                }
            }
        }
        StepFooter(
            primaryTitle = "Next",
            primaryEnabled = selectedCategoryIDs.isNotEmpty(),
            validationMessage = "Select at least 1 task to continue",
            showValidation = showValidation,
            onPrimary = onNext,
            onBack = onBack,
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TaskDetailStep(
    selectedCategoryOptions: List<BookingTaskOption>,
    workingSuggestedTasks: List<BookingChecklistTask>,
    selectedChecklistIDs: Set<UUID>,
    bookingTasks: List<BookingChecklistTask>,
    checklistExpanded: Boolean,
    taskDescriptionDetail: String,
    estimatedTimeLabel: String,
    composerSubtasks: List<BookingChecklistTask>,
    showValidation: Boolean,
    onRemoveCategory: (String) -> Unit,
    onToggleChecklistExpanded: () -> Unit,
    onToggleSuggested: (UUID) -> Unit,
    onConfirmChecklist: () -> Unit,
    onEditTasks: () -> Unit,
    onRemoveTask: (UUID) -> Unit,
    onDescriptionChange: (String) -> Unit,
    onPickEstimatedTime: () -> Unit,
    onAddSubtask: () -> Unit,
    onContinue: () -> Unit,
    onBack: () -> Unit,
) {
    val canContinue = bookingTasks.isNotEmpty() ||
        composerSubtasks.isNotEmpty() ||
        taskDescriptionDetail.trim().isNotEmpty()

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Task Category", color = EmBeColors.MutedText, fontSize = 12.sp)
                if (selectedCategoryOptions.isEmpty()) {
                    Text("No categories selected", color = EmBeColors.MutedText, fontSize = 14.sp)
                } else {
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        selectedCategoryOptions.forEach { option ->
                            Row(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(50))
                                    .background(EmBeColors.BrandOrange)
                                    .padding(horizontal = 10.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(option.title, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                Icon(
                                    Icons.Filled.Close,
                                    contentDescription = "Remove",
                                    tint = Color.White.copy(alpha = 0.9f),
                                    modifier = Modifier
                                        .size(12.dp)
                                        .clickable { onRemoveCategory(option.id) },
                                )
                            }
                        }
                    }
                }
            }

            if (bookingTasks.isEmpty()) {
                SuggestedTasksSection(
                    expanded = checklistExpanded,
                    tasks = workingSuggestedTasks,
                    selectedIDs = selectedChecklistIDs,
                    onToggleExpanded = onToggleChecklistExpanded,
                    onToggleTask = onToggleSuggested,
                    onConfirm = onConfirmChecklist,
                )
            } else {
                ConfirmedTasksSection(
                    expanded = checklistExpanded,
                    tasks = bookingTasks,
                    onToggleExpanded = onToggleChecklistExpanded,
                    onRemove = onRemoveTask,
                    onEdit = onEditTasks,
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color(0xFFF7F8FB))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Checklist, contentDescription = null, tint = EmBeColors.MutedText)
                    Text("Task Details", color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                }
                ComposerField(
                    label = "Description",
                    value = taskDescriptionDetail,
                    onValueChange = onDescriptionChange,
                    placeholder = "Describe the support needed…",
                    singleLine = false,
                )
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Estimated Time", color = EmBeColors.MutedText, fontSize = 12.sp)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, SoftBorder, RoundedCornerShape(10.dp))
                            .clickable(onClick = onPickEstimatedTime)
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(estimatedTimeLabel, color = EmBeColors.DarkText, fontWeight = FontWeight.SemiBold)
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = EmBeColors.MutedText)
                    }
                }
            }

            SubtaskListSection(subtasks = composerSubtasks, onAdd = onAddSubtask)
        }
        StepFooter(
            primaryTitle = "Continue",
            primaryEnabled = canContinue,
            validationMessage = "Add a task, description, or sub-task to continue",
            showValidation = showValidation,
            onPrimary = onContinue,
            onBack = onBack,
        )
    }
}

@Composable
private fun SuggestedTasksSection(
    expanded: Boolean,
    tasks: List<BookingChecklistTask>,
    selectedIDs: Set<UUID>,
    onToggleExpanded: () -> Unit,
    onToggleTask: (UUID) -> Unit,
    onConfirm: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(ChecklistBG),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onToggleExpanded)
                .padding(14.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = Color(0xFF7366BF))
            Text("Suggested Tasks Checklist", color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Icon(
                if (expanded) Icons.Filled.ExpandMore else Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = EmBeColors.MutedText,
            )
        }
        if (expanded) {
            Column(
                modifier = Modifier.padding(horizontal = 14.dp).padding(bottom = 14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                tasks.forEach { task ->
                    val selected = selectedIDs.contains(task.id)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color.White)
                            .clickable { onToggleTask(task.id) }
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Icon(
                            if (selected) Icons.Filled.CheckBox else Icons.Filled.CheckBoxOutlineBlank,
                            contentDescription = null,
                            tint = if (selected) CheckGreen else LinkBlue.copy(alpha = 0.55f),
                        )
                        Column {
                            Text(task.title, color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                            Text(task.category, color = EmBeColors.MutedText, fontSize = 12.sp)
                        }
                    }
                }
                PrimaryOrangeButton(
                    text = "Confirm",
                    enabled = selectedIDs.isNotEmpty(),
                    onClick = onConfirm,
                )
            }
        }
    }
}

@Composable
private fun ConfirmedTasksSection(
    expanded: Boolean,
    tasks: List<BookingChecklistTask>,
    onToggleExpanded: () -> Unit,
    onRemove: (UUID) -> Unit,
    onEdit: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(ConfirmedChecklistBG),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onToggleExpanded)
                .padding(14.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.CheckBox, contentDescription = null, tint = CheckGreen)
            Text("Tasks Checklist", color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Icon(
                if (expanded) Icons.Filled.ExpandMore else Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = EmBeColors.MutedText,
            )
        }
        if (expanded) {
            Column(
                modifier = Modifier.padding(horizontal = 14.dp).padding(bottom = 14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                tasks.forEach { task ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color.White)
                            .padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Icon(Icons.Filled.CheckBox, contentDescription = null, tint = CheckGreen)
                            Column(modifier = Modifier.weight(1f)) {
                                Text(task.title, color = EmBeColors.DarkText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                                Text(task.category, color = EmBeColors.MutedText, fontSize = 12.sp)
                            }
                            Icon(
                                Icons.Filled.Delete,
                                contentDescription = "Remove",
                                tint = EmBeColors.ErrorCoral,
                                modifier = Modifier
                                    .size(18.dp)
                                    .clickable { onRemove(task.id) },
                            )
                        }
                        task.subtasks.forEach { subtask ->
                            Row(
                                modifier = Modifier.padding(start = 28.dp),
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                            ) {
                                Icon(Icons.Filled.CheckBoxOutlineBlank, contentDescription = null, tint = EmBeColors.MutedText)
                                Column {
                                    Text(subtask.title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                    subtask.scheduleSubtitle?.let {
                                        Text(it, color = EmBeColors.MutedText, fontSize = 12.sp)
                                    }
                                }
                            }
                        }
                    }
                }
                PrimaryOrangeButton(text = "Edit Tasks", onClick = onEdit)
            }
        }
    }
}

@Composable
private fun PaymentStep(
    selectedPayment: PaymentMethodKind,
    bankDetails: BankAccountDetails,
    zelleDetails: ContactPaymentDetails,
    venmoDetails: ContactPaymentDetails,
    paypalDetails: ContactPaymentDetails,
    creditCardDetails: CreditCardDetails,
    paymentReady: Boolean,
    onSelect: (PaymentMethodKind) -> Unit,
    onBankChange: (BankAccountDetails) -> Unit,
    onZelleChange: (ContactPaymentDetails) -> Unit,
    onVenmoChange: (ContactPaymentDetails) -> Unit,
    onPaypalChange: (ContactPaymentDetails) -> Unit,
    onCardChange: (CreditCardDetails) -> Unit,
    onContinue: () -> Unit,
    onBack: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text("Payment Method", color = EmBeColors.MutedText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            PaymentMethodKind.entries.forEach { method ->
                val isSelected = selectedPayment == method
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(if (isSelected) PaymentSelectedFill else Color.White)
                        .border(
                            if (isSelected) 1.5.dp else 1.dp,
                            if (isSelected) EmBeColors.BrandOrange else SoftBorder,
                            RoundedCornerShape(14.dp),
                        )
                        .padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(method) },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        PaymentRadio(isSelected)
                        Text(
                            text = method.title,
                            color = if (isSelected) LinkBlue else EmBeColors.DarkText,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.weight(1f),
                        )
                        when (method) {
                            PaymentMethodKind.GiftFund -> Text(
                                "$$GiftBalance",
                                color = LinkBlue,
                                fontWeight = FontWeight.SemiBold,
                            )
                            else -> Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                method.logoResIds.forEach { resId ->
                                    Image(
                                        painter = painterResource(resId),
                                        contentDescription = null,
                                        contentScale = ContentScale.Fit,
                                        modifier = Modifier.height(if (resId == com.embelife.app.R.drawable.pay_visa) 14.dp else 18.dp),
                                    )
                                }
                            }
                        }
                    }
                    if (isSelected) {
                        when (method) {
                            PaymentMethodKind.BankAccount -> {
                                PayField("Account Holder Name", bankDetails.accountHolderName) {
                                    onBankChange(bankDetails.copy(accountHolderName = it))
                                }
                                PayField("Account Number", bankDetails.accountNumber) {
                                    onBankChange(bankDetails.copy(accountNumber = it))
                                }
                                PayField("ABA Routing Number", bankDetails.abaRoutingNumber) {
                                    onBankChange(bankDetails.copy(abaRoutingNumber = it))
                                }
                            }
                            PaymentMethodKind.Zelle -> PayField("Email or Mobile phone number", zelleDetails.contact) {
                                onZelleChange(zelleDetails.copy(contact = it))
                            }
                            PaymentMethodKind.Venmo -> PayField("Venmo username or phone", venmoDetails.contact) {
                                onVenmoChange(venmoDetails.copy(contact = it))
                            }
                            PaymentMethodKind.Paypal -> PayField("PayPal email", paypalDetails.contact) {
                                onPaypalChange(paypalDetails.copy(contact = it))
                            }
                            PaymentMethodKind.GiftFund -> {
                                Text(
                                    "$$GiftBalance",
                                    color = EmBeColors.DarkText,
                                    fontSize = 32.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.fillMaxWidth(),
                                    textAlign = TextAlign.Center,
                                )
                                Text(
                                    "Available gift fund balance",
                                    color = EmBeColors.MutedText,
                                    fontSize = 14.sp,
                                    modifier = Modifier.fillMaxWidth(),
                                    textAlign = TextAlign.Center,
                                )
                            }
                            PaymentMethodKind.CreditCard -> {
                                PayField("Cardholder Name", creditCardDetails.cardholderName) {
                                    onCardChange(creditCardDetails.copy(cardholderName = it))
                                }
                                PayField("Card Number", creditCardDetails.cardNumber) {
                                    onCardChange(creditCardDetails.copy(cardNumber = it))
                                }
                                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                    Box(modifier = Modifier.weight(1f)) {
                                        PayField("Expiry", creditCardDetails.expiry) {
                                            onCardChange(creditCardDetails.copy(expiry = it))
                                        }
                                    }
                                    Box(modifier = Modifier.weight(1f)) {
                                        PayField("CVC", creditCardDetails.cvc) {
                                            onCardChange(creditCardDetails.copy(cvc = it))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        StepFooter(
            primaryTitle = "Continue",
            primaryEnabled = paymentReady,
            onPrimary = onContinue,
            onBack = onBack,
        )
    }
}

@Composable
private fun PaymentRadio(isSelected: Boolean) {
    Box(
        modifier = Modifier
            .size(22.dp)
            .border(1.5.dp, if (isSelected) EmBeColors.BrandOrange else RadioRing, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (isSelected) {
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(EmBeColors.BrandOrange),
            )
        }
    }
}

@Composable
private fun PayField(title: String, value: String, onValueChange: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(title, color = FieldLabel, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(10.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = SoftBorder,
                unfocusedBorderColor = SoftBorder,
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White,
            ),
        )
    }
}

@Composable
private fun SummaryStep(
    provider: Provider,
    selectedDate: LocalDate,
    startTime: LocalTime,
    durationMinutes: Int,
    recipientLabel: String,
    estimatedTotal: Int,
    paymentLabel: String,
    onEdit: () -> Unit,
    onRequest: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.38f)),
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = Color.White,
            shadowElevation = 12.dp,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
        ) {
            Column {
                BookingDetailsChrome(trailing = {
                    Text(
                        text = "Edit",
                        color = LinkBlue,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable(onClick = onEdit),
                    )
                })
                Column(modifier = Modifier.padding(horizontal = 18.dp), verticalArrangement = Arrangement.spacedBy(0.dp)) {
                    Row(modifier = Modifier.padding(bottom = 22.dp)) {
                        SummaryMetaColumn("Booking Dates", selectedDate.format(WideDateFormatter), Modifier.weight(1f))
                        SummaryMetaColumn("To who", recipientLabel, Modifier.weight(1f))
                    }
                    Column(verticalArrangement = Arrangement.spacedBy(18.dp)) {
                        DetailIconRow(Icons.Filled.CalendarToday, "Service Date:", selectedDate.format(ServiceDateFormatter))
                        DetailIconRow(Icons.Filled.Schedule, "Time:", startTime.format(TimeFormatter), "$durationMinutes min")
                        DetailIconRow(Icons.Filled.Face, "Provider", provider.name)
                        DetailIconRow(Icons.Filled.ConfirmationNumber, "Total:", "$$estimatedTotal")
                        DetailIconRow(Icons.Filled.Wallet, "Payment method:", paymentLabel)
                    }
                }
                Text(
                    text = "Request Booking",
                    color = Color.White,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 18.dp)
                        .padding(top = 28.dp, bottom = 20.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(EmBeColors.BrandOrange)
                        .clickable(onClick = onRequest)
                        .padding(vertical = 16.dp),
                )
            }
        }
    }
}

@Composable
private fun RequestedStep(onDismiss: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.38f))
            .clickable(onClick = onDismiss),
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = Color.White,
            shadowElevation = 12.dp,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .clickable(enabled = false) {},
        ) {
            Column {
                BookingDetailsChrome()
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    Icon(
                        Icons.Filled.Outbox,
                        contentDescription = null,
                        tint = Color(0xFF9E99B2),
                        modifier = Modifier
                            .size(52.dp)
                            .padding(top = 8.dp, bottom = 6.dp),
                    )
                    Text("Booking Requested!", color = EmBeColors.DarkText, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    Text(
                        text = "Your booking has been requested and waiting for confirmation from your provider",
                        color = EmBeColors.MutedText,
                        fontSize = 14.sp,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 20.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun BookingDetailsChrome(trailing: @Composable (() -> Unit)? = null) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .padding(top = 18.dp, bottom = 16.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .width(5.dp)
                    .height(22.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(EmBeColors.BrandOrange),
            )
            Spacer(modifier = Modifier.weight(1f))
            trailing?.invoke()
        }
        Text(
            text = "Booking details",
            color = EmBeColors.DarkText,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.align(Alignment.Center),
        )
    }
}

@Composable
private fun SummaryMetaColumn(label: String, value: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label, color = EmBeColors.MutedText, fontSize = 13.sp)
        Text(value, color = EmBeColors.DarkText, fontSize = 17.sp, fontWeight = FontWeight.Bold, maxLines = 2)
    }
}

@Composable
private fun DetailIconRow(
    icon: ImageVector,
    label: String,
    primaryValue: String,
    secondaryValue: String? = null,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(icon, contentDescription = null, tint = Color(0xFF9EA3AD), modifier = Modifier.size(22.dp))
        Text(label, color = EmBeColors.MutedText, fontSize = 14.sp)
        Spacer(modifier = Modifier.weight(1f))
        Column(horizontalAlignment = Alignment.End) {
            Text(primaryValue, color = EmBeColors.DarkText, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.End)
            if (secondaryValue != null) {
                Text(secondaryValue, color = EmBeColors.DarkText, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.End)
            }
        }
    }
}
