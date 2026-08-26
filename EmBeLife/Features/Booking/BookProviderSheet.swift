import SwiftUI

/// Multi-step booking: schedule → who → select category → task detail → payment → summary → requested.
struct BookProviderSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let provider: Provider
    var appointmentType: BookingAppointmentType = .inPerson

    enum Step: Int, CaseIterable {
        case schedule
        case who
        case selectCategory
        case taskDetail
        case payment
        case summary
        case requested
    }

    enum ScheduleField: Hashable {
        case date, start, duration
    }

    @State private var step: Step = .schedule
    @State private var selectedField: ScheduleField = .date

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var startTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now
    @State private var durationMinutes = 30

    @State private var selectedMemberIDs: Set<UUID> = []
    @State private var expandedMemberID: UUID?
    @State private var isAddingMember = false
    @State private var newMemberFirst = ""
    @State private var newMemberLast = ""
    @State private var draftMembers: [FamilyMember] = []

    // Task flow
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var selectedChecklistIDs: Set<UUID> = []
    @State private var workingSuggestedTasks: [BookingChecklistTask] = []
    @State private var bookingTasks: [BookingChecklistTask] = []
    @State private var taskDescriptionDetail = ""
    @State private var estimatedTimeLabel = "30 min"
    @State private var showTaskValidation = false
    @State private var checklistExpanded = true
    @State private var showEstimatedTimePicker = false
    @State private var showAddSubtaskComposer = false
    @State private var composerSubtasks: [BookingChecklistTask] = []

    @State private var selectedPayment: PaymentMethodKind = .creditCard
    @State private var bankDetails = BankAccountDetails.sample
    @State private var zelleDetails = ContactPaymentDetails.zelleSample
    @State private var venmoDetails = ContactPaymentDetails.venmoSample
    @State private var paypalDetails = ContactPaymentDetails.paypalSample
    @State private var creditCardDetails = CreditCardDetails.sample
    @State private var paymentConfirmed = false

    @State private var submittedBookingID: UUID?

    private let durations = [15, 30, 45, 60, 75, 90, 120]
    private let timeEstimates = ["15 min", "30 min", "45 min", "1 hour", "1.5 hours", "2 hours"]
    private let giftBalance = 240
    private let linkBlue = Theme.linkBlue
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let selectedChipFill = Color(red: 0.88, green: 0.93, blue: 1.0)
    private let paymentSelectedFill = Color(red: 1.0, green: 0.847, blue: 0.796)
    private let radioRing = Color(red: 0.70, green: 0.72, blue: 0.76)
    private let fieldLabel = Color(red: 0.10, green: 0.20, blue: 0.45)
    private let checklistBG = Color(red: 0.94, green: 0.93, blue: 0.98)
    private let confirmedChecklistBG = Color(red: 0.90, green: 0.96, blue: 0.92)

    private var availableMembers: [FamilyMember] {
        let profileMembers = appModel.profile.familyMembers
        if !draftMembers.isEmpty {
            return draftMembers
        }
        if !profileMembers.isEmpty {
            return profileMembers
        }
        return FamilyMember.samples
    }

    private var selectedMembers: [FamilyMember] {
        availableMembers.filter { selectedMemberIDs.contains($0.id) }
    }

    private var recipientLabel: String {
        let names = selectedMembers.map(\.displayName)
        if names.isEmpty { return "—" }
        return names.joined(separator: ", ")
    }

    private var estimatedTotal: Int {
        let hours = max(Double(durationMinutes) / 60.0, 0.25)
        return Int((Double(provider.ratePerHour) * hours).rounded())
    }

    private var selectedCategoryOptions: [BookingTaskOption] {
        BookingTaskCatalog.allOptions.filter { selectedCategoryIDs.contains($0.id) }
    }

    private var paymentMethodLabel: String {
        switch selectedPayment {
        case .bankAccount:
            return "Bank account"
        case .zelle:
            return "Zelle"
        case .venmo:
            return "Venmo"
        case .paypal:
            return "PayPal"
        case .giftFund:
            return "Gift Fund"
        case .creditCard:
            let last = creditCardDetails.cardNumber.filter(\.isNumber).suffix(4)
            return last.isEmpty ? "Credit card" : "Credit card · \(String(last))"
        }
    }

    private var canGoForward: Bool {
        switch step {
        case .schedule:
            return true
        case .who:
            return !selectedMemberIDs.isEmpty
        case .selectCategory:
            return !selectedCategoryIDs.isEmpty
        case .taskDetail:
            return !bookingTasks.isEmpty
        case .payment:
            return paymentReady
        case .summary, .requested:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .summary:
                    summaryStep
                case .requested:
                    requestedStep
                default:
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 12)

                        Group {
                            switch step {
                            case .schedule:
                                scheduleStep
                            case .who:
                                whoStep
                            case .selectCategory:
                                selectCategoryStep
                            case .taskDetail:
                                taskDetailStep
                            case .payment:
                                paymentStep
                            case .summary, .requested:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(step == .summary || step == .requested ? Color.clear : Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step != .schedule && step != .summary && step != .requested {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.darkText)
                                .frame(width: 32, height: 32)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Back")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if step != .summary && step != .requested {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.darkText)
                                .frame(width: 32, height: 32)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
            .onAppear {
                seedMembersIfNeeded()
            }
            .toolbar((step == .summary || step == .requested) ? .hidden : .automatic, for: .navigationBar)
            .sheet(isPresented: $showEstimatedTimePicker) {
                NavigationStack {
                    List(timeEstimates, id: \.self) { label in
                        Button {
                            estimatedTimeLabel = label
                            showEstimatedTimePicker = false
                        } label: {
                            HStack {
                                Text(label)
                                Spacer()
                                if estimatedTimeLabel == label {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(linkBlue)
                                }
                            }
                        }
                    }
                    .navigationTitle("Estimated Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showEstimatedTimePicker = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showAddSubtaskComposer) {
                AddSubTaskComposerView(
                    onCancel: { showAddSubtaskComposer = false },
                    onSave: { task in
                        composerSubtasks.append(task)
                        showAddSubtaskComposer = false
                    }
                )
                .presentationDetents([.large])
            }
        }
        .presentationDetents(bookingPresentationDetents)
        .presentationDragIndicator(step == .summary || step == .requested ? .hidden : .visible)
        .presentationCornerRadius(step == .summary || step == .requested ? 0 : 28)
        .presentationBackground(step == .summary || step == .requested ? Color.clear : Color(.systemBackground))
        .interactiveDismissDisabled(step == .summary)
    }

    private var bookingPresentationDetents: Set<PresentationDetent> {
        switch step {
        case .requested, .summary:
            return [.large]
        default:
            return [.large]
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.brandOrange)
                .frame(width: 4, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                if step == .schedule || step == .who {
                    Text(provider.name)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// Design header: orange accent left, title centered, optional Edit on the right.
    private func bookingDetailsChrome() -> some View {
        bookingDetailsChrome { EmptyView() }
    }

    private func bookingDetailsChrome<Trailing: View>(
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        ZStack {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Theme.brandOrange)
                    .frame(width: 5, height: 22)
                Spacer(minLength: 0)
                trailing()
            }

            Text("Booking details")
                .font(.scaledSystem(size: 18, weight: .bold))
                .foregroundStyle(Theme.darkText)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private var headerTitle: String {
        switch step {
        case .schedule, .who: "Book a Provider"
        case .selectCategory: "Select category"
        case .taskDetail: "Detail"
        case .payment: "Set up payment"
        case .summary, .requested: "Booking details"
        }
    }

    // MARK: - Navigation

    private func goBack() {
        showTaskValidation = false
        withAnimation(.easeInOut(duration: 0.2)) {
            switch step {
            case .schedule, .requested:
                break
            case .who:
                step = .schedule
            case .selectCategory:
                step = .who
            case .taskDetail:
                step = .selectCategory
            case .payment:
                step = .taskDetail
            case .summary:
                step = .payment
            }
        }
    }

    private func goForward() {
        switch step {
        case .schedule:
            withAnimation(.easeInOut(duration: 0.2)) { step = .who }
        case .who:
            if selectedMemberIDs.isEmpty {
                isAddingMember = true
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = .selectCategory }
        case .selectCategory:
            if selectedCategoryIDs.isEmpty {
                withAnimation { showTaskValidation = true }
                return
            }
            // Seed checklist selection from category chips when entering detail.
            if bookingTasks.isEmpty {
                rebuildSuggestedTasks(selectAllIfEmpty: true)
            }
            showTaskValidation = false
            withAnimation(.easeInOut(duration: 0.2)) { step = .taskDetail }
        case .taskDetail:
            ensureComposerTaskIfNeeded()
            if bookingTasks.isEmpty {
                withAnimation { showTaskValidation = true }
                return
            }
            showTaskValidation = false
            withAnimation(.easeInOut(duration: 0.2)) { step = .payment }
        case .payment:
            guard paymentReady else { return }
            paymentConfirmed = true
            withAnimation(.easeInOut(duration: 0.2)) { step = .summary }
        case .summary:
            submitBookingRequest()
        case .requested:
            break
        }
    }

    private func rebuildSuggestedTasks(selectAllIfEmpty: Bool = false) {
        let previouslyCheckedTitles = Set(
            workingSuggestedTasks
                .filter { selectedChecklistIDs.contains($0.id) }
                .map(\.title)
        )
        workingSuggestedTasks = BookingTaskCatalog.suggestedChecklist(from: selectedCategoryOptions)
        if previouslyCheckedTitles.isEmpty, selectAllIfEmpty {
            selectedChecklistIDs = Set(workingSuggestedTasks.map(\.id))
        } else {
            selectedChecklistIDs = Set(
                workingSuggestedTasks
                    .filter { previouslyCheckedTitles.contains($0.title) }
                    .map(\.id)
            )
        }
    }

    private func stepFooter(
        primaryTitle: String,
        primaryEnabled: Bool = true,
        showBack: Bool = true,
        validationMessage: String? = nil
    ) -> some View {
        VStack(spacing: 10) {
            if let validationMessage, showTaskValidation {
                Text(validationMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.errorCoral)
            }
            Button(primaryTitle) {
                goForward()
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .opacity(primaryEnabled ? 1 : 0.55)
            .disabled(!primaryEnabled && step != .taskDetail && step != .selectCategory)

            if showBack, step != .schedule, step != .summary, step != .requested {
                Button("Back") {
                    goBack()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Step 1: Schedule

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a day and time you want to schedule")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                dateField
                HStack(spacing: 12) {
                    startTimeField
                    durationField
                }
            }
            .padding(.horizontal, 20)

            Group {
                switch selectedField {
                case .date:
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(linkBlue)
                    .padding(.horizontal, 12)
                case .start:
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                case .duration:
                    durationList
                }
            }
            .frame(maxHeight: 320)

            Spacer(minLength: 0)

            stepFooter(primaryTitle: "Next Step", showBack: false)
        }
    }

    private var durationList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(durationMinutes) min")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    durationMinutes = 30
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(linkBlue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(durations, id: \.self) { minutes in
                        Button {
                            durationMinutes = minutes
                        } label: {
                            Text("\(minutes) min")
                                .font(.body.weight(durationMinutes == minutes ? .semibold : .regular))
                                .foregroundStyle(Theme.darkText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background {
                                    if durationMinutes == minutes {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(red: 0.94, green: 0.95, blue: 0.96))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }

    private var dateField: some View {
        selectionCard(isActive: selectedField == .date) {
            selectedField = .date
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(selectedDate, format: .dateTime.month(.wide).day().year())
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(linkBlue)
            }
        }
    }

    private var startTimeField: some View {
        selectionCard(isActive: selectedField == .start) {
            selectedField = .start
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(startTime, format: .dateTime.hour().minute())
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.grayscale70)
            }
        }
    }

    private var durationField: some View {
        selectionCard(isActive: selectedField == .duration) {
            selectedField = .duration
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text("\(durationMinutes) min")
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.grayscale70)
            }
        }
    }

    // MARK: - Step 2: Who

    private var whoStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Who will you book for")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(red: 0.18, green: 0.22, blue: 0.32))

                    Text("Member List")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.mutedText)

                    VStack(spacing: 12) {
                        ForEach(availableMembers) { member in
                            memberRow(member)
                        }
                    }

                    if isAddingMember {
                        addMemberForm
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAddingMember = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(softBorder, lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                    Text("+")
                                        .font(.title3)
                                        .foregroundStyle(Theme.mutedText)
                                }
                                Text("Adding member")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.darkText)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }

            stepFooter(
                primaryTitle: "Continue",
                primaryEnabled: !selectedMemberIDs.isEmpty
            )
            .opacity(selectedMemberIDs.isEmpty ? 0.55 : 1)
        }
    }

    private func memberRow(_ member: FamilyMember) -> some View {
        let selected = selectedMemberIDs.contains(member.id)
        let expanded = expandedMemberID == member.id

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if selected {
                            selectedMemberIDs.remove(member.id)
                        } else {
                            selectedMemberIDs.insert(member.id)
                        }
                    }
                } label: {
                    Image(systemName: selected ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(selected ? Color(red: 0.20, green: 0.70, blue: 0.40) : linkBlue.opacity(0.55))
                }
                .buttonStyle(.plain)

                Circle()
                    .fill(member.avatarStyle.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(member.monogram)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedMemberID = expanded ? nil : member.id
                        if !selected {
                            selectedMemberIDs.insert(member.id)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(member.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mutedText)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }

            if expanded {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred Service")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mutedText)
                        ForEach(member.preferredServices, id: \.self) { service in
                            Text(service)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.darkText)
                        }
                        if member.preferredServices.isEmpty {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(softBorder)
                        .frame(width: 1)
                        .padding(.horizontal, 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mutedText)
                        ForEach(member.preferredTimes, id: \.self) { time in
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(Theme.mutedText)
                                Text(time)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.darkText)
                            }
                        }
                        if member.preferredTimes.isEmpty {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
            }
        }
    }

    private var addMemberForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add family or friend")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            HStack(spacing: 10) {
                TextField("First name", text: $newMemberFirst)
                    .textFieldStyle(.roundedBorder)
                TextField("Last name", text: $newMemberLast)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    withAnimation {
                        isAddingMember = false
                        newMemberFirst = ""
                        newMemberLast = ""
                    }
                }
                .foregroundStyle(Theme.mutedText)

                Spacer()

                Button("Add") {
                    addMemberFromForm()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(canAddMember ? Theme.brandOrange : Theme.grayscale60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(!canAddMember)
            }
        }
        .padding(14)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var canAddMember: Bool {
        !newMemberFirst.trimmingCharacters(in: .whitespaces).isEmpty
            && !newMemberLast.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Step 3: Select category

    private var selectCategoryStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Choose at least one care task category for this visit")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)

                    ForEach(BookingTaskCatalog.groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.mutedText)
                                Text(group.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.darkText)
                            }

                            FlowLayout(spacing: 8) {
                                ForEach(group.options) { option in
                                    categoryChip(option)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            stepFooter(
                primaryTitle: "Next",
                primaryEnabled: !selectedCategoryIDs.isEmpty,
                validationMessage: "Select at least 1 task to continue"
            )
        }
    }

    private func categoryChip(_ option: BookingTaskOption) -> some View {
        let selected = selectedCategoryIDs.contains(option.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                if selected {
                    selectedCategoryIDs.remove(option.id)
                } else {
                    selectedCategoryIDs.insert(option.id)
                }
                // Keep booking tasks in sync when categories change
                bookingTasks = []
                selectedChecklistIDs = []
                workingSuggestedTasks = []
                showTaskValidation = false
            }
        } label: {
            HStack(spacing: 6) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(linkBlue)
                }
                Text(option.title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color(red: 0.15, green: 0.25, blue: 0.55) : Theme.darkText)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(selected ? selectedChipFill : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? linkBlue.opacity(0.45) : softBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4: Task detail / checklist

    private var taskDetailStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Selected category chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Category")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)

                        if selectedCategoryOptions.isEmpty {
                            Text("No categories selected")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)
                        } else {
                            FlowLayout(spacing: 8) {
                                ForEach(selectedCategoryOptions) { option in
                                    HStack(spacing: 6) {
                                        Text(option.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Button {
                                            selectedCategoryIDs.remove(option.id)
                                            bookingTasks = []
                                            rebuildSuggestedTasks(selectAllIfEmpty: true)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.white.opacity(0.9))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Theme.brandOrange)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // After Confirm: only the confirmed checklist remains.
                    if bookingTasks.isEmpty {
                        suggestedTasksSection
                    } else {
                        confirmedTasksSection
                    }

                    // Task details form
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.clipboard")
                                .foregroundStyle(Theme.mutedText)
                            Text("Task Details")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.darkText)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            TextField("Describe the support needed…", text: $taskDescriptionDetail, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(softBorder, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Estimated Time")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            Button {
                                showEstimatedTimePicker = true
                            } label: {
                                HStack {
                                    Text(estimatedTimeLabel)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(softBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add any relevant files/ photos")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            HStack {
                                Text("Optional attachments")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.mutedText)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Theme.mutedText)
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(softBorder, lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.97, green: 0.975, blue: 0.985))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    SubtaskListSection(subtasks: composerSubtasks) {
                        showAddSubtaskComposer = true
                    }
                }
                .padding(20)
            }

            stepFooter(
                primaryTitle: "Continue",
                primaryEnabled: !bookingTasks.isEmpty || !composerSubtasks.isEmpty || !taskDescriptionDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                validationMessage: "Add a task, description, or sub-task to continue"
            )
        }
    }

    private var suggestedTasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    checklistExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.75))
                    Text("Suggested Tasks Checklist")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.darkText)
                    Spacer()
                    Image(systemName: checklistExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if checklistExpanded {
                VStack(spacing: 10) {
                    ForEach(workingSuggestedTasks) { task in
                        suggestedTaskRow(task)
                    }

                    Button {
                        confirmChecklistSelection()
                    } label: {
                        Text("Confirm")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedChecklistIDs.isEmpty
                                    ? Theme.grayscale60
                                    : Theme.brandOrange
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedChecklistIDs.isEmpty)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(checklistBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var confirmedTasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    checklistExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(Color(red: 0.20, green: 0.70, blue: 0.40))
                    Text("Tasks Checklist")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.darkText)
                    Spacer()
                    Image(systemName: checklistExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if checklistExpanded {
                VStack(spacing: 10) {
                    ForEach(bookingTasks) { task in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.square.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(red: 0.20, green: 0.70, blue: 0.40))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                    Text(task.category)
                                        .font(.caption)
                                        .foregroundStyle(Theme.mutedText)
                                }
                                Spacer(minLength: 0)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        bookingTasks.removeAll { $0.id == task.id }
                                        if bookingTasks.isEmpty {
                                            rebuildSuggestedTasks(selectAllIfEmpty: true)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.errorCoral)
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(task.subtasks) { subtask in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "square")
                                        .foregroundStyle(Theme.mutedText)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(subtask.title)
                                            .font(.subheadline.weight(.semibold))
                                        if let subtitle = subtask.scheduleSubtitle {
                                            Text(subtitle)
                                                .font(.caption)
                                                .foregroundStyle(Theme.mutedText)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.leading, 28)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        // Reopen suggested checklist so user can change selections.
                        withAnimation(.easeInOut(duration: 0.2)) {
                            let confirmedTitles = Set(bookingTasks.map(\.title))
                            workingSuggestedTasks = BookingTaskCatalog.suggestedChecklist(from: selectedCategoryOptions)
                            selectedChecklistIDs = Set(
                                workingSuggestedTasks
                                    .filter { confirmedTitles.contains($0.title) }
                                    .map(\.id)
                            )
                            if selectedChecklistIDs.isEmpty {
                                selectedChecklistIDs = Set(workingSuggestedTasks.map(\.id))
                            }
                            bookingTasks = []
                        }
                    } label: {
                        Text("Edit Tasks")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.brandOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(confirmedChecklistBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func suggestedTaskRow(_ task: BookingChecklistTask) -> some View {
        let selected = selectedChecklistIDs.contains(task.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                if selected {
                    selectedChecklistIDs.remove(task.id)
                } else {
                    selectedChecklistIDs.insert(task.id)
                }
                showTaskValidation = false
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(selected ? Color(red: 0.20, green: 0.70, blue: 0.40) : linkBlue.opacity(0.55))
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .multilineTextAlignment(.leading)
                    Text(task.category)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func confirmChecklistSelection() {
        let chosen = workingSuggestedTasks.filter { selectedChecklistIDs.contains($0.id) }
        guard !chosen.isEmpty else {
            withAnimation { showTaskValidation = true }
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            bookingTasks = chosen.map { task in
                var copy = task
                if !taskDescriptionDetail.isEmpty {
                    copy.detailDescription = taskDescriptionDetail
                }
                return copy
            }
            attachComposerSubtasksToBookingTasks()
            checklistExpanded = true
            showTaskValidation = false
        }
    }

    private func ensureComposerTaskIfNeeded() {
        if bookingTasks.isEmpty {
            let trimmed = taskDescriptionDetail.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = trimmed.isEmpty ? composerSubtasks.first?.title : trimmed
            guard let title, !title.isEmpty else { return }
            let option = selectedCategoryOptions.first
            bookingTasks = [
                BookingChecklistTask(
                    title: title,
                    category: option?.categoryTitle ?? "Custom task",
                    subcategory: option?.title ?? title,
                    detailDescription: trimmed,
                    estimatedMinutes: BookingChecklistTask.minutes(fromEstimateLabel: estimatedTimeLabel)
                )
            ]
        }
        attachComposerSubtasksToBookingTasks()
    }

    private func attachComposerSubtasksToBookingTasks() {
        guard !composerSubtasks.isEmpty, !bookingTasks.isEmpty else { return }
        bookingTasks[0].subtasks = composerSubtasks
    }

    // MARK: - Step 5: Payment

    private var paymentStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Payment Method")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)

                    ForEach(PaymentMethodKind.allCases) { method in
                        paymentMethodCard(method)
                    }
                }
                .padding(20)
            }

            stepFooter(
                primaryTitle: "Continue",
                primaryEnabled: paymentReady
            )
        }
    }

    private var paymentReady: Bool {
        switch selectedPayment {
        case .bankAccount:
            return !bankDetails.accountHolderName.isEmpty
                && !bankDetails.accountNumber.isEmpty
                && !bankDetails.abaRoutingNumber.isEmpty
        case .zelle:
            return !zelleDetails.contact.isEmpty
        case .venmo:
            return !venmoDetails.contact.isEmpty
        case .paypal:
            return !paypalDetails.contact.isEmpty
        case .giftFund:
            return giftBalance > 0
        case .creditCard:
            return !creditCardDetails.cardNumber.isEmpty
                && !creditCardDetails.expiry.isEmpty
                && !creditCardDetails.cvc.isEmpty
        }
    }

    private func paymentMethodCard(_ method: PaymentMethodKind) -> some View {
        let isSelected = selectedPayment == method
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPayment = method
                    paymentConfirmed = false
                }
            } label: {
                HStack(spacing: 12) {
                    paymentRadio(isSelected: isSelected)
                    Text(method.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isSelected ? linkBlue : Theme.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    trailingPaymentAccessory(method)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected {
                paymentFields(for: method)
            }
        }
        .padding(14)
        .background(isSelected ? paymentSelectedFill : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Theme.brandOrange : softBorder, lineWidth: isSelected ? 1.5 : 1)
        )
    }

    @ViewBuilder
    private func paymentFields(for method: PaymentMethodKind) -> some View {
        switch method {
        case .bankAccount:
            payField("Account Holder Name", text: $bankDetails.accountHolderName)
            payField("Account Number", text: $bankDetails.accountNumber)
            payField("ABA Routing Number", text: $bankDetails.abaRoutingNumber)
        case .zelle:
            payField("Email or Mobile phone number", text: $zelleDetails.contact)
        case .venmo:
            payField("Venmo username or phone", text: $venmoDetails.contact)
        case .paypal:
            payField("PayPal email", text: $paypalDetails.contact)
        case .giftFund:
            Text("$\(giftBalance)")
                .font(.scaledSystem(size: 32, weight: .bold))
                .frame(maxWidth: .infinity)
            Text("Available gift fund balance")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .frame(maxWidth: .infinity)
        case .creditCard:
            payField("Cardholder Name", text: $creditCardDetails.cardholderName)
            payField("Card Number", text: $creditCardDetails.cardNumber)
            HStack(spacing: 10) {
                payField("Expiry", text: $creditCardDetails.expiry)
                payField("CVC", text: $creditCardDetails.cvc)
            }
        }
    }

    private func payField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(fieldLabel)
            TextField(title, text: text)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(softBorder, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func trailingPaymentAccessory(_ method: PaymentMethodKind) -> some View {
        switch method {
        case .giftFund:
            Text("$\(giftBalance)")
                .font(.body.weight(.semibold))
                .foregroundStyle(linkBlue)
        case .zelle, .venmo, .paypal, .creditCard:
            HStack(spacing: 6) {
                ForEach(method.logoAssetNames, id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: name == "payVisa" ? 14 : 18)
                        .frame(maxWidth: 40)
                }
            }
        case .bankAccount:
            EmptyView()
        }
    }

    private func paymentRadio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Theme.brandOrange : radioRing, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            Circle()
                .fill(Theme.brandOrange)
                .frame(width: 12, height: 12)
                .scaleEffect(isSelected ? 1 : 0.001)
                .opacity(isSelected ? 1 : 0)
        }
    }

    // MARK: - Step 6: Summary (review before request)

    private var summaryStep: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 24)
                summaryCard
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 0) {
            bookingDetailsChrome {
                Button("Edit") {
                    goBack()
                }
                .font(.scaledSystem(size: 16, weight: .semibold))
                .foregroundStyle(linkBlue)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    summaryMetaColumn(label: "Booking Dates", value: bookingDateLabel)
                    summaryMetaColumn(label: "To who", value: recipientLabel)
                }
                .padding(.bottom, 22)

                VStack(spacing: 18) {
                    detailIconRow(
                        icon: "calendar",
                        label: "Service Date:",
                        value: serviceDateLabel
                    )
                    detailIconRow(
                        icon: "clock",
                        label: "Time:",
                        primaryValue: startTimeLabel,
                        secondaryValue: "\(durationMinutes) min"
                    )
                    detailIconRow(
                        icon: "face.smiling",
                        label: "Provider",
                        value: provider.name
                    )
                    detailIconRow(
                        icon: "ticket",
                        label: "Total:",
                        value: "$\(estimatedTotal)"
                    )
                    detailIconRow(
                        icon: "wallet.pass",
                        label: "Payment method:",
                        value: summaryPaymentLabel
                    )
                }
            }
            .padding(.horizontal, 18)

            Button("Request Booking") {
                goForward()
            }
            .font(.scaledSystem(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.brandOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 24, y: 8)
    }

    private var summaryPaymentLabel: String {
        switch selectedPayment {
        case .bankAccount: return "Bank account"
        case .zelle: return "Zelle"
        case .venmo: return "Venmo"
        case .paypal: return "PayPal"
        case .giftFund: return "Gift Fund"
        case .creditCard: return "Credit card"
        }
    }

    private func summaryMetaColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.scaledSystem(size: 13, weight: .regular))
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.scaledSystem(size: 17, weight: .bold))
                .foregroundStyle(Theme.darkText)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailIconRow(
        icon: String,
        label: String,
        value: String
    ) -> some View {
        detailIconRow(icon: icon, label: label, primaryValue: value, secondaryValue: nil)
    }

    private func detailIconRow(
        icon: String,
        label: String,
        primaryValue: String,
        secondaryValue: String?
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.scaledSystem(size: 17, weight: .regular))
                .foregroundStyle(Color(red: 0.62, green: 0.64, blue: 0.68))
                .frame(width: 22, height: 22)

            Text(label)
                .font(.scaledSystem(size: 14, weight: .regular))
                .foregroundStyle(Theme.mutedText)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(primaryValue)
                    .font(.scaledSystem(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.darkText)
                    .multilineTextAlignment(.trailing)
                if let secondaryValue {
                    Text(secondaryValue)
                        .font(.scaledSystem(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.darkText)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    // MARK: - Step 7: Requested confirmation

    private var requestedStep: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack {
                Spacer(minLength: 24)
                requestedCard
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 28)
        }
        .accessibilityAction(.escape) { dismiss() }
    }

    private var requestedCard: some View {
        VStack(spacing: 0) {
            bookingDetailsChrome()

            VStack(spacing: 14) {
                Image(systemName: "tray.and.arrow.up")
                    .font(.scaledSystem(size: 52, weight: .light))
                    .foregroundStyle(Color(red: 0.62, green: 0.60, blue: 0.70))
                    .symbolRenderingMode(.monochrome)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                Text("Booking Requested!")
                    .font(.scaledSystem(size: 22, weight: .bold))
                    .foregroundStyle(Theme.darkText)

                Text("Your booking has been requested and waiting for confirmation from your provider")
                    .font(.scaledSystem(size: 14, weight: .regular))
                    .foregroundStyle(Theme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 24, y: 8)
    }

    // MARK: - Shared

    private func selectionCard<Content: View>(
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? linkBlue : Color(.separator), lineWidth: isActive ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var bookingDateLabel: String {
        selectedDate.formatted(.dateTime.month(.wide).day().year())
    }

    private var serviceDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, yyyy"
        return f.string(from: selectedDate)
    }

    private var startTimeLabel: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    private func seedMembersIfNeeded() {
        if draftMembers.isEmpty {
            draftMembers = appModel.profile.familyMembers.isEmpty
                ? FamilyMember.samples
                : appModel.profile.familyMembers
        }
        if selectedMemberIDs.isEmpty, let first = draftMembers.first {
            selectedMemberIDs = [first.id]
            expandedMemberID = first.id
        }
    }

    private func addMemberFromForm() {
        let member = FamilyMember(
            firstName: newMemberFirst.trimmingCharacters(in: .whitespaces),
            lastName: newMemberLast.trimmingCharacters(in: .whitespaces),
            preferredServices: ["Personal care/ hygiene"],
            preferredTimes: ["8am – 10am"],
            avatarStyle: .next(after: draftMembers.count)
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            draftMembers.append(member)
            selectedMemberIDs.insert(member.id)
            expandedMemberID = member.id
            isAddingMember = false
            newMemberFirst = ""
            newMemberLast = ""
            // Persist lightly onto profile so Profile also shows them after publish...
            var profile = appModel.profile
            profile.familyMembers = draftMembers
            appModel.profile = profile
        }
    }

    private func submitBookingRequest() {
        paymentConfirmed = true
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let combinedStart = calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? startTime

        let primaryTitle = bookingTasks.first.map { $0.title } ?? "\(provider.title) with \(provider.name)"
        let descriptionText: String = {
            if let first = bookingTasks.first, !first.detailDescription.isEmpty {
                return first.detailDescription
            }
            return "\(appointmentType.title) · \(durationMinutes) min · $\(estimatedTotal) · \(paymentMethodLabel)"
        }()

        attachComposerSubtasksToBookingTasks()

        let booking = Booking(
            provider: provider,
            date: selectedDate,
            startTime: combinedStart,
            durationMinutes: durationMinutes,
            status: .requested,
            serviceProvidedTo: recipientLabel,
            title: primaryTitle,
            taskDescription: descriptionText,
            location: appModel.profile.address.isEmpty ? "Service location TBD" : appModel.profile.address,
            checklistTasks: bookingTasks.isEmpty ? Booking.defaultChecklist : bookingTasks
        )
        appModel.addBooking(booking)
        submittedBookingID = booking.id
        withAnimation(.easeInOut(duration: 0.2)) {
            step = .requested
        }
    }
}
