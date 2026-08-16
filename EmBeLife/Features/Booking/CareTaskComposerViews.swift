import PhotosUI
import SwiftUI

/// Shared chrome for Add Task / Add Sub-Task (design: circular back + orange Done).
struct AddTaskNavHeader: View {
    let title: String
    var doneEnabled: Bool = true
    var onBack: () -> Void
    var onDone: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Back")

            Spacer(minLength: 8)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.darkText)

            Spacer(minLength: 8)

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.brandOrange.opacity(doneEnabled ? 1 : 0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(!doneEnabled)
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

struct TaskComposerFieldCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "list.clipboard")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
                Text("Task Details")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
            }

            content
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }
}

struct TaskComposerLabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            content
        }
    }
}

struct TaskComposerOutlineField: View {
    var body: some View {
        EmptyView()
    }

    static func stroke() -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color(red: 0.88, green: 0.89, blue: 0.91), lineWidth: 1)
    }
}

struct SubtaskListSection: View {
    let subtasks: [BookingChecklistTask]
    var onAdd: () -> Void
    var onToggle: ((BookingChecklistTask) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sub-Task")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.darkText)

            if subtasks.isEmpty {
                VStack(spacing: 6) {
                    Text("No Sub-Task added")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.darkText)
                    Text("Subtitle goes here")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.88, green: 0.89, blue: 0.91), lineWidth: 1)
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(subtasks) { task in
                        Button {
                            onToggle?(task)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "square")
                                    .font(.title3)
                                    .foregroundStyle(Theme.mutedText)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.darkText)
                                        .multilineTextAlignment(.leading)
                                    if let subtitle = task.scheduleSubtitle ?? (task.detailDescription.isEmpty ? nil : task.detailDescription) {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(red: 0.88, green: 0.89, blue: 0.91), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(action: onAdd) {
                Text("Add Sub-Task")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.18, green: 0.18, blue: 0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add Sub-Task")
        }
    }
}

struct SuggestedTasksBanner: View {
    var action: () -> Void

    private let fill = Color(red: 0.92, green: 0.90, blue: 0.97)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.75))
                Text("Suggested Tasks Checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
            }
            .padding(14)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Suggested Tasks Checklist")
    }
}

struct EstimatedTimePickerSheet: View {
    @Binding var isPresented: Bool
    var selectedLabel: String
    var onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List(BookingChecklistTask.estimateOptions, id: \.self) { label in
                Button {
                    onSelect(label)
                    isPresented = false
                } label: {
                    HStack {
                        Text(label)
                            .foregroundStyle(Theme.darkText)
                        Spacer()
                        if selectedLabel == label {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.linkBlue)
                        }
                    }
                }
            }
            .navigationTitle("Estimated Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// Add Sub-Task form matching Add_Task_3 / Add_Task_4.
struct AddSubTaskComposerView: View {
    var onCancel: () -> Void
    var onSave: (BookingChecklistTask) -> Void

    @State private var name = ""
    @State private var descriptionText = ""
    @State private var estimatedLabel = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var showTimePicker = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var attachmentNames: [String] = []
    @State private var showValidation = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            AddTaskNavHeader(
                title: "Add Sub-Task",
                doneEnabled: canSave
            ) {
                onCancel()
            } onDone: {
                save()
            }

            Divider().opacity(0.5)

            ScrollView {
                TaskComposerFieldCard {
                    TaskComposerLabeledField(label: "Name") {
                        TextField("", text: $name)
                            .font(.body.weight(.semibold))
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(TaskComposerOutlineField.stroke())
                    }

                    TaskComposerLabeledField(label: "Description") {
                        TextField("", text: $descriptionText, axis: .vertical)
                            .font(.body.weight(.semibold))
                            .lineLimit(3...6)
                            .padding(12)
                            .frame(minHeight: 88, alignment: .topLeading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(TaskComposerOutlineField.stroke())
                    }

                    TaskComposerLabeledField(label: "Estimated Time/Due time") {
                        Button {
                            showTimePicker = true
                        } label: {
                            HStack {
                                Text(timeFieldLabel)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(timeFieldLabel.isEmpty ? Color.clear : Theme.darkText)
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
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.mutedText)
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(TaskComposerOutlineField.stroke())
                        }
                    }
                }
                .padding(16)

                if showValidation {
                    Text("Enter a sub-task name to continue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.errorCoral)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        .sheet(isPresented: $showTimePicker) {
            EstimatedTimePickerSheet(isPresented: $showTimePicker, selectedLabel: estimatedLabel) { label in
                estimatedLabel = label
                hasDueDate = true
                dueDate = Calendar.current.date(byAdding: .minute, value: BookingChecklistTask.minutes(fromEstimateLabel: label) ?? 30, to: Date()) ?? Date()
            }
        }
        .onChange(of: photoItems) { _, items in
            attachmentNames = items.enumerated().map { "Photo \($0.offset + 1)" }
        }
    }

    private var timeFieldLabel: String {
        if !estimatedLabel.isEmpty { return estimatedLabel }
        if hasDueDate { return dueDate.formatted(date: .omitted, time: .shortened) }
        return ""
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showValidation = true
            return
        }
        let task = BookingChecklistTask(
            title: trimmed,
            category: "Sub-Task",
            subcategory: trimmed,
            deadline: hasDueDate ? dueDate : nil,
            detailDescription: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            estimatedMinutes: BookingChecklistTask.minutes(fromEstimateLabel: estimatedLabel),
            attachmentNames: attachmentNames
        )
        onSave(task)
    }
}
