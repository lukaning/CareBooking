import SwiftUI

/// Multi-step booking: schedule → who → task details → payment → summary → requested booking.
struct BookProviderSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let provider: Provider
    var appointmentType: BookingAppointmentType = .inPerson

    enum Step: Int, CaseIterable {
        case schedule
        case who
        case tasks
        case payment
        case summary
    }

    enum ScheduleField: Hashable {
        case date, start, duration
    }

    @State private var step: Step = .schedule
    @State private var selectedField: ScheduleField = .duration

    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var startTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now
    @State private var durationMinutes = 30

    @State private var selectedMemberIDs: Set<UUID> = []
    @State private var expandedMemberID: UUID?
    @State private var isAddingMember = false
    @State private var newMemberFirst = ""
    @State private var newMemberLast = ""
    @State private var draftMembers: [FamilyMember] = []

    // Task details
    @State private var bookingTasks: [BookingChecklistTask] = []
    @State private var taskSearch = ""
    @State private var selectedTaskCategoryID: String?
    @State private var selectedTaskGroupID: String?
    @State private var isComposingTask = false
    @State private var composeCategoryTitle = ""
    @State private var composeSubcategoryTitle = ""
    @State private var composeTitle = ""
    @State private var composePriority: BookingTaskPriority = .medium
    @State private var composeHasDeadline = false
    @State private var composeDeadline = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var composeDescription = ""
    @State private var showTaskValidation = false

    @State private var selectedPayment: PaymentMethodKind = .creditCard
    @State private var bankDetails = BankAccountDetails.sample
    @State private var zelleDetails = ContactPaymentDetails.zelleSample
    @State private var venmoDetails = ContactPaymentDetails.venmoSample
    @State private var paypalDetails = ContactPaymentDetails.paypalSample
    @State private var creditCardDetails = CreditCardDetails.sample
    @State private var paymentConfirmed = false

    @State private var submittedBookingID: UUID?

    private let durations = [15, 30, 45, 60, 75, 90, 120]
    private let giftBalance = 240
    private let linkBlue = Theme.linkBlue
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let selectedFill = Color(red: 1.0, green: 0.847, blue: 0.796)
    private let radioRing = Color(red: 0.70, green: 0.72, blue: 0.76)
    private let fieldLabel = Color(red: 0.10, green: 0.20, blue: 0.45)

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

    var body: some View {
        NavigationStack {
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
                    case .tasks:
                        tasksStep
                    case .payment:
                        paymentStep
                    case .summary:
                        summaryStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            .onAppear {
                seedMembersIfNeeded()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
                if step != .payment && step != .summary && step != .tasks {
                    Text(provider.name)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var headerTitle: String {
        switch step {
        case .payment: "Set up payment"
        case .tasks: "Task details"
        case .summary: "Booking details"
        default: "Book a Provider"
        }
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

            Button("Next Step") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .who
                }
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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

            Button("Continue") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedMemberIDs.isEmpty {
                        isAddingMember = true
                    } else {
                        step = .tasks
                    }
                }
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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

    // MARK: - Step 3: Task details

    private var tasksStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Add the care tasks for this visit")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)

                    if !bookingTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Added tasks (\(bookingTasks.count))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.darkText)
                            ForEach(bookingTasks) { task in
                                addedTaskCard(task)
                            }
                        }
                    }

                    if isComposingTask {
                        composeTaskForm
                    } else {
                        taskCatalogBrowser
                    }
                }
                .padding(20)
            }

            VStack(spacing: 10) {
                if showTaskValidation && bookingTasks.isEmpty {
                    Text("Add at least one task to continue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.errorCoral)
                }
                Button("Continue") {
                    if bookingTasks.isEmpty {
                        withAnimation { showTaskValidation = true }
                    } else {
                        showTaskValidation = false
                        withAnimation(.easeInOut(duration: 0.2)) {
                            step = .payment
                        }
                    }
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
                .opacity(bookingTasks.isEmpty ? 0.7 : 1)

                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isComposingTask = false
                        step = .who
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var taskCatalogBrowser: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.mutedText)
                TextField("Search tasks or equipment support", text: $taskSearch)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color(red: 0.96, green: 0.965, blue: 0.975))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Choose category")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ServiceCategory.all) { category in
                        let selected = selectedTaskCategoryID == category.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTaskCategoryID = category.id
                                selectedTaskGroupID = nil
                            }
                        } label: {
                            Text(shortCategoryTitle(category.title))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selected ? .white : Theme.darkText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(selected ? Theme.brandOrange : Color(red: 0.94, green: 0.95, blue: 0.97))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let categoryID = selectedTaskCategoryID {
                if OnboardingServiceCatalog.usesNestedOptions(categoryID) {
                    let groups = filteredGroups(for: categoryID)
                    Text("Sub-category")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)

                    ForEach(groups) { group in
                        let expanded = selectedTaskGroupID == group.id
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedTaskGroupID = expanded ? nil : group.id
                                }
                            } label: {
                                HStack {
                                    Text(group.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                    Spacer()
                                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(softBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if expanded {
                                ForEach(filteredOptions(group.children)) { option in
                                    taskOptionRow(
                                        option,
                                        categoryTitle: categoryTitle(for: categoryID),
                                        subcategoryTitle: group.title
                                    )
                                }
                            }
                        }
                    }
                } else {
                    Text("Select a task")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)

                    ForEach(filteredOptions(OnboardingServiceCatalog.subOptions(for: categoryID))) { option in
                        taskOptionRow(
                            option,
                            categoryTitle: categoryTitle(for: categoryID),
                            subcategoryTitle: option.title
                        )
                    }
                }
            } else if !taskSearch.trimmingCharacters(in: .whitespaces).isEmpty {
                // Global search across categories
                Text("Search results")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
                ForEach(globalSearchResults, id: \.id) { hit in
                    taskOptionRow(
                        hit.option,
                        categoryTitle: hit.categoryTitle,
                        subcategoryTitle: hit.groupTitle ?? hit.option.title
                    )
                }
                if globalSearchResults.isEmpty {
                    Text("No matching tasks")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            } else {
                Text("Pick a category or search above to add tasks.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
                    .padding(.top, 4)
            }
        }
    }

    private func taskOptionRow(
        _ option: ServiceSubOption,
        categoryTitle: String,
        subcategoryTitle: String
    ) -> some View {
        Button {
            beginComposeTask(
                categoryTitle: categoryTitle,
                subcategoryTitle: subcategoryTitle,
                suggestedTitle: option.title
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.brandOrange)
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                    Text(categoryTitle)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(softBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var composeTaskForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Add task details")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                Spacer()
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isComposingTask = false
                        resetComposeForm()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            }

            // Context summary card
            VStack(alignment: .leading, spacing: 8) {
                summaryKV("Category", composeCategoryTitle)
                if !composeSubcategoryTitle.isEmpty {
                    summaryKV("Sub-category", composeSubcategoryTitle)
                }
                summaryKV("Rate", "$\(provider.ratePerHour)/hour")
                summaryKV("Duration", "\(durationMinutes) min")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.97, green: 0.975, blue: 0.985))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            formLabeledField("Title of task", required: true) {
                TextField("e.g. Morning hygiene routine", text: $composeTitle)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                showTaskValidation && composeTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Theme.errorCoral
                                    : softBorder,
                                lineWidth: 1
                            )
                    )
            }

            formLabeledField("Priority", required: false) {
                Picker("Priority", selection: $composePriority) {
                    ForEach(BookingTaskPriority.allCases) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }

            formLabeledField("Deadline", required: false) {
                Toggle(isOn: $composeHasDeadline) {
                    Text(composeHasDeadline ? "Set deadline" : "No deadline")
                        .font(.subheadline)
                        .foregroundStyle(Theme.darkText)
                }
                .tint(Theme.brandOrange)
                if composeHasDeadline {
                    DatePicker(
                        "Deadline",
                        selection: $composeDeadline,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
            }

            formLabeledField("Description", required: false) {
                TextField("Describe what support is needed…", text: $composeDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(softBorder, lineWidth: 1)
                    )
            }

            Button("Add details") {
                addComposedTask()
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                composeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.black.opacity(0.35)
                    : Color.black
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(composeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
        .background(Color(red: 0.985, green: 0.985, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formLabeledField<Content: View>(
        _ title: String,
        required: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(fieldLabel)
                if required {
                    Text("*")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.errorCoral)
                }
            }
            content()
        }
    }

    private func summaryKV(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)
            Spacer(minLength: 0)
        }
    }

    private func addedTaskCard(_ task: BookingChecklistTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                Text(task.categoryPathLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(task.priority.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(priorityColor(task.priority))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(task.priority).opacity(0.12))
                        .clipShape(Capsule())
                    if let deadline = task.deadline {
                        Text(deadline.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.mutedText)
                    }
                }
                if !task.detailDescription.isEmpty {
                    Text(task.detailDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Button {
                withAnimation {
                    bookingTasks.removeAll { $0.id == task.id }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.errorCoral)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(softBorder, lineWidth: 1)
        )
    }

    private func priorityColor(_ priority: BookingTaskPriority) -> Color {
        switch priority {
        case .low: Color(red: 0.35, green: 0.55, blue: 0.95)
        case .medium: Theme.brandOrange
        case .high: Theme.errorCoral
        }
    }

    private func beginComposeTask(categoryTitle: String, subcategoryTitle: String, suggestedTitle: String) {
        composeCategoryTitle = categoryTitle
        composeSubcategoryTitle = subcategoryTitle
        composeTitle = suggestedTitle
        composePriority = .medium
        composeHasDeadline = false
        composeDeadline = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        composeDescription = ""
        showTaskValidation = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isComposingTask = true
        }
    }

    private func addComposedTask() {
        let title = composeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            showTaskValidation = true
            return
        }
        let task = BookingChecklistTask(
            title: title,
            category: composeCategoryTitle,
            subcategory: composeSubcategoryTitle,
            priority: composePriority,
            deadline: composeHasDeadline ? composeDeadline : nil,
            detailDescription: composeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            bookingTasks.append(task)
            isComposingTask = false
            resetComposeForm()
            showTaskValidation = false
        }
    }

    private func resetComposeForm() {
        composeCategoryTitle = ""
        composeSubcategoryTitle = ""
        composeTitle = ""
        composePriority = .medium
        composeHasDeadline = false
        composeDescription = ""
    }

    private func shortCategoryTitle(_ title: String) -> String {
        if title.count <= 22 { return title }
        let first = title.split(separator: "/").first.map(String.init) ?? title
        if first.count <= 28 { return first }
        return String(first.prefix(24)) + "…"
    }

    private func categoryTitle(for id: String) -> String {
        ServiceCategory.all.first(where: { $0.id == id })?.title ?? id
    }

    private func filteredOptions(_ options: [ServiceSubOption]) -> [ServiceSubOption] {
        let q = taskSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return options }
        return options.filter { $0.title.lowercased().contains(q) }
    }

    private func filteredGroups(for categoryID: String) -> [ServiceOptionGroup] {
        let groups = OnboardingServiceCatalog.optionGroups(for: categoryID)
        let q = taskSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return groups }
        return groups.compactMap { group in
            let children = group.children.filter {
                $0.title.lowercased().contains(q) || group.title.lowercased().contains(q)
            }
            if children.isEmpty && !group.title.lowercased().contains(q) {
                return nil
            }
            return ServiceOptionGroup(
                id: group.id,
                title: group.title,
                children: children.isEmpty ? group.children : children
            )
        }
    }

    private struct TaskSearchHit: Identifiable {
        var id: String { "\(categoryID)-\(option.id)" }
        let categoryID: String
        let categoryTitle: String
        let groupTitle: String?
        let option: ServiceSubOption
    }

    private var globalSearchResults: [TaskSearchHit] {
        let q = taskSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        var hits: [TaskSearchHit] = []
        for category in ServiceCategory.all {
            if OnboardingServiceCatalog.usesNestedOptions(category.id) {
                for group in OnboardingServiceCatalog.optionGroups(for: category.id) {
                    for option in group.children where option.title.lowercased().contains(q)
                        || group.title.lowercased().contains(q)
                        || category.title.lowercased().contains(q)
                    {
                        hits.append(
                            TaskSearchHit(
                                categoryID: category.id,
                                categoryTitle: category.title,
                                groupTitle: group.title,
                                option: option
                            )
                        )
                    }
                }
            } else {
                for option in OnboardingServiceCatalog.subOptions(for: category.id)
                    where option.title.lowercased().contains(q) || category.title.lowercased().contains(q)
                {
                    hits.append(
                        TaskSearchHit(
                            categoryID: category.id,
                            categoryTitle: category.title,
                            groupTitle: nil,
                            option: option
                        )
                    )
                }
            }
        }
        return hits
    }

    // MARK: - Step 4: Payment

    private var paymentStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Payment Method")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.darkText)

                    ForEach(PaymentMethodKind.allCases) { method in
                        paymentMethodCard(method)
                    }
                }
                .padding(20)
            }

            Button {
                confirmPaymentAndSummarize()
            } label: {
                Text("Request Booking")
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .disabled(!paymentReady)
            .opacity(paymentReady ? 1 : 0.55)
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
        .background(isSelected ? selectedFill : Color.white)
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
                .font(.system(size: 32, weight: .bold))
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

    // MARK: - Step 5: Summary

    private var summaryStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Booking details")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.darkText)

                    summaryRow(label: "Booking Dates", value: bookingDateLabel)
                    summaryRow(label: "To who", value: recipientLabel)

                    if !bookingTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Task details")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.darkText)
                            ForEach(bookingTasks) { task in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(task.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                    Text(task.categoryPathLabel)
                                        .font(.caption)
                                        .foregroundStyle(Theme.mutedText)
                                    HStack(spacing: 8) {
                                        Text("Priority: \(task.priority.rawValue)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(priorityColor(task.priority))
                                        if let deadline = task.deadline {
                                            Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundStyle(Theme.mutedText)
                                        }
                                    }
                                    if !task.detailDescription.isEmpty {
                                        Text(task.detailDescription)
                                            .font(.caption)
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(red: 0.97, green: 0.975, blue: 0.985))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }

                    labeledIconRow(icon: "calendar", title: "Service Date", value: serviceDateLabel)
                    labeledIconRow(
                        icon: "clock",
                        title: "Time",
                        value: "\(startTimeLabel)\n\(durationMinutes) min"
                    )
                    labeledIconRow(icon: "face.smiling", title: "Provider", value: provider.name)
                    labeledIconRow(icon: "receipt", title: "Total", value: "$\(estimatedTotal)")
                    labeledIconRow(icon: "creditcard", title: "Payment method", value: paymentMethodLabel)

                    VStack(spacing: 12) {
                        Image(systemName: "tray.and.arrow.up.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.brandOrange)
                            .padding(.top, 12)

                        Text("Booking Requested!")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.darkText)

                        Text("Your booking has been requested and waiting for confirmation from your provider.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .padding(20)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func labeledIconRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.brandOrange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
            }
            Spacer()
        }
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

    private func confirmPaymentAndSummarize() {
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
            step = .summary
        }
    }
}
