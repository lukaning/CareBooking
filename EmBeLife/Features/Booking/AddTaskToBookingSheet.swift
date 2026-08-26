import PhotosUI
import SwiftUI

/// Flow for appending a care task (and optional sub-tasks) to a Requested or Booked appointment.
struct AddTaskToBookingSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let bookingID: UUID
    /// When set, Done saves a sub-task onto this existing checklist item instead of a new parent task.
    var parentTaskID: UUID? = nil
    /// When set, Done updates this checklist item in place.
    var editingTask: BookingChecklistTask? = nil

    private enum Screen {
        case addTask
        case suggested
        case addSubtask
    }

    @State private var screen: Screen
    @State private var selectedCategoryID: String?
    @State private var descriptionText = ""
    @State private var estimatedLabel = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var attachmentNames: [String] = []
    @State private var subtasks: [BookingChecklistTask] = []
    @State private var selectedSuggestedIDs: Set<UUID> = []
    @State private var workingSuggestedTasks: [BookingChecklistTask] = []
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var showTimePicker = false
    @State private var showCategoryPicker = false
    @State private var showValidation = false

    private let linkBlue = Theme.linkBlue
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let selectedChipFill = Color(red: 0.88, green: 0.93, blue: 1.0)
    private let pageBG = Color(red: 0.96, green: 0.96, blue: 0.97)

    init(bookingID: UUID, parentTaskID: UUID? = nil, editingTask: BookingChecklistTask? = nil) {
        self.bookingID = bookingID
        self.parentTaskID = parentTaskID
        self.editingTask = editingTask
        _screen = State(initialValue: parentTaskID == nil ? .addTask : .addSubtask)
        if let editingTask {
            let matched = BookingTaskCatalog.allOptions.first {
                $0.title == editingTask.subcategory || $0.title == editingTask.title
            }
            _selectedCategoryID = State(initialValue: matched?.id)
            let description = editingTask.detailDescription.isEmpty ? editingTask.title : editingTask.detailDescription
            _descriptionText = State(initialValue: description)
            if let minutes = editingTask.estimatedMinutes {
                _estimatedLabel = State(initialValue: BookingChecklistTask.estimateLabel(for: minutes))
            }
            _attachmentNames = State(initialValue: editingTask.attachmentNames)
            _subtasks = State(initialValue: editingTask.subtasks)
        }
    }

    private var selectedCategoryOption: BookingTaskOption? {
        BookingTaskCatalog.allOptions.first { $0.id == selectedCategoryID }
    }

    private var categoryPlaceholder: String {
        selectedCategoryOption?.title ?? "Select one of the following category"
    }

    private var canSaveTask: Bool {
        let hasBody = !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategoryOption != nil
            || !subtasks.isEmpty
        return hasBody
    }

    var body: some View {
        Group {
            switch screen {
            case .addTask:
                addTaskScreen
            case .suggested:
                suggestedScreen
            case .addSubtask:
                AddSubTaskComposerView(
                    onCancel: {
                        if parentTaskID != nil {
                            dismiss()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) { screen = .addTask }
                        }
                    },
                    onSave: { task in
                        if let parentTaskID {
                            appModel.appendSubtask(to: bookingID, parentTaskID: parentTaskID, subtask: task)
                            dismiss()
                        } else {
                            subtasks.append(task)
                            withAnimation(.easeInOut(duration: 0.2)) { screen = .addTask }
                        }
                    }
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Add Task

    private var addTaskScreen: some View {
        VStack(spacing: 0) {
            AddTaskNavHeader(
                title: editingTask == nil ? "Add Task" : "Edit Task",
                doneEnabled: canSaveTask
            ) {
                dismiss()
            } onDone: {
                save()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SuggestedTasksBanner {
                        rebuildSuggestedTasks(selectAllIfEmpty: workingSuggestedTasks.isEmpty)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            screen = .suggested
                        }
                    }

                    TaskComposerFieldCard {
                        TaskComposerLabeledField(label: "Task Category") {
                            Button {
                                showCategoryPicker = true
                            } label: {
                                HStack {
                                    Text(categoryPlaceholder)
                                        .font(.subheadline.weight(selectedCategoryOption == nil ? .regular : .semibold))
                                        .foregroundStyle(selectedCategoryOption == nil ? Theme.mutedText : Theme.darkText)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(TaskComposerOutlineField.stroke())
                            }
                            .buttonStyle(.plain)
                        }

                        TaskComposerLabeledField(label: "Description") {
                            TextField("", text: $descriptionText, axis: .vertical)
                                .font(.body.weight(.semibold))
                                .lineLimit(3...6)
                                .padding(12)
                                .frame(minHeight: 72, alignment: .topLeading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(TaskComposerOutlineField.stroke())
                        }

                        TaskComposerLabeledField(label: "Estimated Time") {
                            Button {
                                showTimePicker = true
                            } label: {
                                HStack {
                                    Text(estimatedLabel.isEmpty ? " " : estimatedLabel)
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
                                .overlay(TaskComposerOutlineField.stroke())
                            }
                            .buttonStyle(.plain)
                        }

                        TaskComposerLabeledField(label: "Add any relevant files/ photos") {
                            PhotosPicker(selection: $photoItems, maxSelectionCount: 6, matching: .images) {
                                HStack {
                                    if attachmentNames.isEmpty {
                                        Color.clear.frame(height: 20)
                                    } else {
                                        Text(attachmentNames.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.darkText)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.body)
                                        .foregroundStyle(Color(red: 0.62, green: 0.58, blue: 0.82))
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(TaskComposerOutlineField.stroke())
                            }
                        }
                    }

                    SubtaskListSection(subtasks: subtasks) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            screen = .addSubtask
                        }
                    }

                    if showValidation {
                        Text("Add a category, description, or sub-task before tapping Done")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.errorCoral)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .background(pageBG)
        .sheet(isPresented: $showTimePicker) {
            EstimatedTimePickerSheet(isPresented: $showTimePicker, selectedLabel: estimatedLabel) { label in
                estimatedLabel = label
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            categoryPickerSheet
        }
        .onChange(of: photoItems) { _, items in
            attachmentNames = items.enumerated().map { "Photo \($0.offset + 1)" }
        }
    }

    private var categoryPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(BookingTaskCatalog.groups) { group in
                    Section(group.title) {
                        ForEach(group.options) { option in
                            Button {
                                selectedCategoryID = option.id
                                if descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    descriptionText = option.title
                                }
                                showCategoryPicker = false
                            } label: {
                                HStack {
                                    Text(option.title)
                                        .foregroundStyle(Theme.darkText)
                                    Spacer()
                                    if selectedCategoryID == option.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(linkBlue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Task Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showCategoryPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Suggested checklist

    private var suggestedScreen: some View {
        VStack(spacing: 0) {
            AddTaskNavHeader(title: "Add Task") {
                withAnimation(.easeInOut(duration: 0.2)) { screen = .addTask }
            } onDone: {
                applySuggestedSelection()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(BookingTaskCatalog.groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.darkText)
                            FlowLayout(spacing: 8) {
                                ForEach(group.options) { option in
                                    suggestedCategoryChip(option)
                                }
                            }
                        }
                    }

                    if !appModel.savedTaskTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Saved for next time")
                                .font(.subheadline.weight(.bold))
                            ForEach(appModel.savedTaskTemplates) { task in
                                suggestedRow(task)
                            }
                        }
                    }

                    if !workingSuggestedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Suggested Tasks Checklist")
                                .font(.subheadline.weight(.bold))
                            ForEach(workingSuggestedTasks) { task in
                                suggestedRow(task)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(pageBG)
    }

    private func suggestedCategoryChip(_ option: BookingTaskOption) -> some View {
        let selected = selectedCategoryIDs.contains(option.id)
        return Button {
            if selected {
                selectedCategoryIDs.remove(option.id)
            } else {
                selectedCategoryIDs.insert(option.id)
            }
            rebuildSuggestedTasks(selectAllIfEmpty: true)
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

    private func suggestedRow(_ task: BookingChecklistTask) -> some View {
        let selected = selectedSuggestedIDs.contains(task.id)
        return Button {
            if selected {
                selectedSuggestedIDs.remove(task.id)
            } else {
                selectedSuggestedIDs.insert(task.id)
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

    // MARK: - Persistence

    private func rebuildSuggestedTasks(selectAllIfEmpty: Bool) {
        let options = BookingTaskCatalog.allOptions.filter { selectedCategoryIDs.contains($0.id) }
        let previouslyChecked = Set(
            workingSuggestedTasks.filter { selectedSuggestedIDs.contains($0.id) }.map(\.title)
        )
        workingSuggestedTasks = BookingTaskCatalog.suggestedChecklist(from: options)
        if previouslyChecked.isEmpty, selectAllIfEmpty {
            selectedSuggestedIDs = Set(workingSuggestedTasks.map(\.id))
        } else {
            selectedSuggestedIDs = Set(
                workingSuggestedTasks.filter { previouslyChecked.contains($0.title) }.map(\.id)
            )
        }
    }

    private func applySuggestedSelection() {
        let catalogChosen = workingSuggestedTasks.filter { selectedSuggestedIDs.contains($0.id) }
        let savedChosen = appModel.savedTaskTemplates.filter { selectedSuggestedIDs.contains($0.id) }
        let chosen = catalogChosen + savedChosen
        if let first = chosen.first {
            selectedCategoryID = BookingTaskCatalog.allOptions.first {
                $0.title == first.title && $0.categoryTitle == first.category
            }?.id ?? selectedCategoryID
            if descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                descriptionText = first.title
            }
            let extra = Array(chosen.dropFirst())
            for item in extra where !subtasks.contains(where: { $0.title == item.title }) {
                subtasks.append(
                    BookingChecklistTask(
                        title: item.title,
                        category: item.category,
                        subcategory: item.subcategory,
                        detailDescription: item.detailDescription
                    )
                )
            }
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            screen = .addTask
        }
    }

    private func save() {
        guard let task = makeParentTask(id: editingTask?.id) else {
            showValidation = true
            return
        }
        if editingTask != nil {
            appModel.replaceChecklistTask(in: bookingID, task: task)
        } else {
            appModel.appendChecklistTasks(to: bookingID, tasks: [task])
        }
        dismiss()
    }

    private func makeParentTask(id: UUID? = nil) -> BookingChecklistTask? {
        let option = selectedCategoryOption
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedDescription.isEmpty ? (option?.title ?? subtasks.first?.title) : trimmedDescription
        guard let title, !title.isEmpty else { return nil }

        return BookingChecklistTask(
            id: id ?? UUID(),
            title: title,
            category: option?.categoryTitle ?? editingTask?.category ?? "Custom task",
            subcategory: option?.title ?? editingTask?.subcategory ?? title,
            priority: editingTask?.priority ?? .medium,
            deadline: editingTask?.deadline,
            detailDescription: trimmedDescription,
            estimatedMinutes: BookingChecklistTask.minutes(fromEstimateLabel: estimatedLabel),
            attachmentNames: attachmentNames,
            subtasks: subtasks
        )
    }
}

// MARK: - CTA

/// Full-width orange "Add Task" button used on Requested / Booked booking cards.
struct AddTaskCTAButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Add Task")
                .font(.scaledSystem(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.brandOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Task")
    }
}
