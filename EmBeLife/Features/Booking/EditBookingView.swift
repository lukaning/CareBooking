import SwiftUI

/// Booking detail + edit flow (title, description, services, schedule, location, checklist).
struct EditBookingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let bookingID: UUID

    @State private var isEditing = false
    @State private var checklistExpanded = true
    @State private var showReschedule = false
    @State private var showCancelConfirm = false
    @State private var showSavedBanner = false
    @State private var showAddTask = false

    @State private var draftTitle = ""
    @State private var draftDescription = ""
    @State private var draftServiceProvidedTo = ""
    @State private var draftLocation = ""
    @State private var draftDurationMinutes = 120
    @State private var draftTasks: [BookingChecklistTask] = []
    @State private var newTaskTitle = ""
    @State private var newTaskPriority: BookingTaskPriority = .medium
    @State private var newTaskDescription = ""
    @State private var newTaskHasDeadline = false
    @State private var newTaskDeadline = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var isAddingTaskDetail = false

    private let bodyDark = Color(red: 0.12, green: 0.14, blue: 0.18)
    private let labelMuted = Color(red: 0.45, green: 0.48, blue: 0.56)
    private let iconMuted = Color(red: 0.42, green: 0.45, blue: 0.52)
    private let cardFill = Color(red: 0.988, green: 0.988, blue: 0.988)
    private let cardShadow = Color(red: 0.835, green: 0.835, blue: 0.902).opacity(0.5)
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)

    private let durationOptions = [30, 60, 90, 120, 150, 180]

    private var booking: Booking? {
        appModel.booking(id: bookingID)
    }

    var body: some View {
        Group {
            if let booking {
                content(booking)
            } else {
                ContentUnavailableView("Booking Not Found", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(isEditing ? "Edit Booking" : "Booking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(bodyDark)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if booking != nil, booking?.status != .completed {
                    Button {
                        if isEditing {
                            saveEdits()
                        } else {
                            loadDraftFromBooking()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditing = true
                            }
                        }
                    } label: {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(bodyDark)
                            .frame(width: 36, height: 36)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isEditing ? "Save" : "Edit")
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showReschedule) {
            if let booking {
                RescheduleBookingSheet(booking: booking)
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskToBookingSheet(bookingID: bookingID)
        }
        .confirmationDialog(
            "Cancel this booking?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Cancel booking", role: .destructive) {
                appModel.cancelBooking(id: bookingID)
                dismiss()
            }
            Button("Keep booking", role: .cancel) {}
        } message: {
            Text("This removes the booking from your list. You can book the provider again later.")
        }
        .onAppear {
            loadDraftFromBooking()
        }
        .overlay(alignment: .top) {
            if showSavedBanner {
                Text("Booking updated")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.brandOrange)
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func content(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection(booking)
                    detailCards(booking)
                    checklistSection(booking)

                    if booking.status != .completed {
                        actionSection(booking)
                    }
                }
                .padding(20)
                .padding(.bottom, isEditing ? 80 : 12)
            }

            if isEditing {
                Button("Save changes") {
                    saveEdits()
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Color(.systemBackground)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                )
            }
        }
    }

    // MARK: - Header

    private func headerSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(labelMuted)
                    TextField("Booking title", text: $draftTitle)
                        .font(.title3.weight(.semibold))
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(softBorder, lineWidth: 1)
                        )
                }
            } else {
                Text(booking.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(bodyDark)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundStyle(bodyDark)
                if isEditing {
                    TextField("Describe the care tasks…", text: $draftDescription, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(softBorder, lineWidth: 1)
                        )
                } else {
                    Text(booking.taskDescription)
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale60)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Provider")
                        .font(.headline)
                        .foregroundStyle(bodyDark)
                    HStack(spacing: 10) {
                        Image(booking.provider.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        Text(booking.provider.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(bodyDark)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Date Created")
                        .font(.headline)
                        .foregroundStyle(bodyDark)
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(iconMuted)
                        Text(booking.dateCreated, format: .dateTime.month(.abbreviated).day().year())
                            .font(.subheadline)
                            .foregroundStyle(bodyDark)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Detail cards

    private func detailCards(_ booking: Booking) -> some View {
        VStack(spacing: 14) {
            if isEditing {
                editableField(icon: "person.crop.circle", label: "Services provided to") {
                    TextField("Who is care for?", text: $draftServiceProvidedTo)
                        .font(.body.weight(.semibold))
                }

                detailCard(
                    icon: "calendar",
                    label: "Date",
                    value: formattedDate(booking.date),
                    accessory: {
                        Button("Change") { showReschedule = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.linkBlue)
                    }
                )

                detailCard(
                    icon: "clock",
                    label: "Time",
                    value: timeRangeLabel(for: booking),
                    accessory: {
                        Button("Change") { showReschedule = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.linkBlue)
                    }
                )

                VStack(alignment: .leading, spacing: 8) {
                    Label("Duration", systemImage: "hourglass")
                        .font(.caption)
                        .foregroundStyle(labelMuted)
                    Picker("Duration", selection: $draftDurationMinutes) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text(durationLabel(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: cardShadow, radius: 6, y: 4)

                editableField(icon: "house", label: "Location") {
                    TextField("Service location", text: $draftLocation)
                        .font(.body.weight(.semibold))
                }

                detailCard(
                    icon: "dollarsign.circle",
                    label: "Rate",
                    value: "$\(booking.provider.ratePerHour)/Hour"
                )
            } else {
                detailCard(
                    icon: "person.crop.circle",
                    label: "Services provided to",
                    value: booking.serviceProvidedTo.isEmpty ? "Not specified" : booking.serviceProvidedTo
                )
                detailCard(
                    icon: "calendar",
                    label: "Date",
                    value: formattedDate(booking.date)
                )
                detailCard(
                    icon: "clock",
                    label: "Time",
                    value: booking.timeRangeWithDurationLabel
                )
                detailCard(
                    icon: "house",
                    label: "Location",
                    value: booking.location
                )
                detailCard(
                    icon: "dollarsign.circle",
                    label: "Rate",
                    value: "$\(booking.provider.ratePerHour)/Hour"
                )
            }
        }
    }

    private func detailCard(icon: String, label: String, value: String) -> some View {
        detailCard(icon: icon, label: label, value: value) { EmptyView() }
    }

    private func detailCard<Accessory: View>(
        icon: String,
        label: String,
        value: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconMuted)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(labelMuted)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(bodyDark)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            accessory()
        }
        .padding(16)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: cardShadow, radius: 6, y: 4)
    }

    private func editableField<Content: View>(
        icon: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconMuted)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(labelMuted)
                content()
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: cardShadow, radius: 6, y: 4)
    }

    // MARK: - Checklist / Task details

    private func checklistSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    checklistExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(iconMuted)
                    Text("Task details")
                        .font(.headline)
                        .foregroundStyle(bodyDark)
                    Spacer()
                    Image(systemName: checklistExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(labelMuted)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if checklistExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tasks and care activities scheduled for this booking.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale70)
                        .fixedSize(horizontal: false, vertical: true)

                    let tasks = isEditing ? draftTasks : booking.checklistTasks
                    ForEach(tasks) { task in
                        taskDetailCard(task, canDelete: isEditing)
                    }

                    if isEditing {
                        if isAddingTaskDetail {
                            editComposeForm
                        } else {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isAddingTaskDetail = true
                                }
                            } label: {
                                Text("Add task details")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.brandOrange)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    } else if booking.status != .completed {
                        AddTaskCTAButton {
                            showAddTask = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: cardShadow, radius: 6, y: 4)
        .onChange(of: showAddTask) { _, isPresented in
            if !isPresented {
                loadDraftFromBooking()
            }
        }
    }

    private func taskDetailCard(_ task: BookingChecklistTask, canDelete: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(bodyDark)
                Text(task.categoryPathLabel)
                    .font(.caption)
                    .foregroundStyle(labelMuted)
                HStack(spacing: 8) {
                    Text(task.priority.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(priorityColor(task.priority))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(priorityColor(task.priority).opacity(0.12))
                        .clipShape(Capsule())
                    if let deadline = task.deadline {
                        Label(
                            deadline.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "calendar"
                        )
                        .font(.caption2)
                        .foregroundStyle(labelMuted)
                    }
                }
                if !task.detailDescription.isEmpty {
                    Text(task.detailDescription)
                        .font(.caption)
                        .foregroundStyle(labelMuted)
                }
            }
            Spacer(minLength: 8)
            if canDelete {
                Button {
                    draftTasks.removeAll { $0.id == task.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.errorCoral)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var editComposeForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add task details")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(bodyDark)

            TextField("Title of task", text: $newTaskTitle)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(softBorder, lineWidth: 1)
                )

            Picker("Priority", selection: $newTaskPriority) {
                ForEach(BookingTaskPriority.allCases) { priority in
                    Text(priority.rawValue).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Deadline", isOn: $newTaskHasDeadline)
                .tint(Theme.brandOrange)
            if newTaskHasDeadline {
                DatePicker(
                    "Deadline",
                    selection: $newTaskDeadline,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            TextField("Description", text: $newTaskDescription, axis: .vertical)
                .lineLimit(2...5)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(softBorder, lineWidth: 1)
                )

            HStack(spacing: 10) {
                Button("Cancel") {
                    withAnimation {
                        isAddingTaskDetail = false
                        resetNewTaskForm()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(labelMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.93, green: 0.94, blue: 0.96))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("Add details") {
                    addTask()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty
                        ? Color.black.opacity(0.35)
                        : Color.black
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
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

    // MARK: - Actions

    private func actionSection(_ booking: Booking) -> some View {
        VStack(spacing: 12) {
            if !isEditing {
                Button {
                    showReschedule = true
                } label: {
                    Text("Reschedule")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    loadDraftFromBooking()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = true
                    }
                } label: {
                    Text("Edit booking")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(bodyDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.93, green: 0.94, blue: 0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                showCancelConfirm = true
            } label: {
                Text("Cancel booking")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.errorCoral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Data

    private func loadDraftFromBooking() {
        guard let booking else { return }
        draftTitle = booking.title
        draftDescription = booking.taskDescription
        draftServiceProvidedTo = booking.serviceProvidedTo
        draftLocation = booking.location
        draftDurationMinutes = booking.durationMinutes
        draftTasks = booking.checklistTasks
        isAddingTaskDetail = false
        resetNewTaskForm()
    }

    private func saveEdits() {
        guard var booking else { return }
        booking.title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? booking.title
            : draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        booking.taskDescription = draftDescription
        booking.serviceProvidedTo = draftServiceProvidedTo
        booking.location = draftLocation
        booking.durationMinutes = draftDurationMinutes
        booking.checklistTasks = draftTasks
        appModel.updateBooking(booking)

        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
            isAddingTaskDetail = false
            showSavedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSavedBanner = false
            }
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        draftTasks.append(
            BookingChecklistTask(
                title: title,
                category: "Custom",
                subcategory: "",
                priority: newTaskPriority,
                deadline: newTaskHasDeadline ? newTaskDeadline : nil,
                detailDescription: newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        isAddingTaskDetail = false
        resetNewTaskForm()
    }

    private func resetNewTaskForm() {
        newTaskTitle = ""
        newTaskPriority = .medium
        newTaskDescription = ""
        newTaskHasDeadline = false
        newTaskDeadline = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    private func timeRangeLabel(for booking: Booking) -> String {
        "\(booking.startTime.formatted(date: .omitted, time: .shortened)) - \(booking.endTime.formatted(date: .omitted, time: .shortened))"
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1h" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
