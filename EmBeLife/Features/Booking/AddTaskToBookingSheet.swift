import SwiftUI

/// Flow for appending care tasks to an existing Requested or Booked appointment.
struct AddTaskToBookingSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let bookingID: UUID

    private enum Step {
        case selectCategory
        case detail
    }

    @State private var step: Step = .selectCategory
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var selectedChecklistIDs: Set<UUID> = []
    @State private var workingSuggestedTasks: [BookingChecklistTask] = []
    @State private var confirmedTasks: [BookingChecklistTask] = []
    @State private var taskDescriptionDetail = ""
    @State private var showValidation = false
    @State private var checklistExpanded = true

    private let linkBlue = Theme.linkBlue
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let selectedChipFill = Color(red: 0.88, green: 0.93, blue: 1.0)
    private let checklistBG = Color(red: 0.94, green: 0.93, blue: 0.98)
    private let confirmedChecklistBG = Color(red: 0.90, green: 0.96, blue: 0.92)

    private var booking: Booking? {
        appModel.booking(id: bookingID)
    }

    private var selectedCategoryOptions: [BookingTaskOption] {
        BookingTaskCatalog.allOptions.filter { selectedCategoryIDs.contains($0.id) }
    }

    private var canSave: Bool {
        !confirmedTasks.isEmpty || !selectedChecklistIDs.isEmpty
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
                    case .selectCategory:
                        selectCategoryStep
                    case .detail:
                        detailStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .detail {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                step = .selectCategory
                            }
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.brandOrange)
                .frame(width: 4, height: 22)
            Text(step == .selectCategory ? "Select category" : "Add Task")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.darkText)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Select category

    private var selectCategoryStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let booking {
                        Text("Add tasks to your \(booking.status == .booked ? "booked" : "requested") visit with \(booking.provider.name)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedText)
                    }

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

            footerBar(
                title: "Next",
                enabled: !selectedCategoryIDs.isEmpty,
                validation: "Select at least 1 task to continue"
            ) {
                guard !selectedCategoryIDs.isEmpty else {
                    withAnimation { showValidation = true }
                    return
                }
                rebuildSuggestedTasks(selectAllIfEmpty: true)
                confirmedTasks = []
                showValidation = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .detail
                }
            }
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
                showValidation = false
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

    // MARK: - Detail / confirm

    private var detailStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if confirmedTasks.isEmpty {
                        suggestedSection
                    } else {
                        confirmedSection
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (optional)")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)
                        TextField("Describe the support needed…", text: $taskDescriptionDetail, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(softBorder, lineWidth: 1)
                            )
                    }
                    .padding(14)
                    .background(Color(red: 0.97, green: 0.975, blue: 0.985))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }

            footerBar(
                title: "Add Task",
                enabled: canSave,
                validation: "Confirm at least 1 task to add"
            ) {
                saveTasks()
            }
        }
    }

    private var suggestedSection: some View {
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
                        suggestedRow(task)
                    }

                    Button {
                        confirmChecklist()
                    } label: {
                        Text("Confirm")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedChecklistIDs.isEmpty ? Theme.grayscale60 : Theme.brandOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedChecklistIDs.isEmpty)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(checklistBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var confirmedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.square.fill")
                    .foregroundStyle(Color(red: 0.20, green: 0.70, blue: 0.40))
                Text("Tasks Checklist")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                Spacer()
            }
            .padding(14)

            VStack(spacing: 10) {
                ForEach(confirmedTasks) { task in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.square.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.20, green: 0.70, blue: 0.40))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.subheadline.weight(.semibold))
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

                Button {
                    withAnimation {
                        confirmedTasks = []
                        rebuildSuggestedTasks(selectAllIfEmpty: true)
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
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(confirmedChecklistBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func suggestedRow(_ task: BookingChecklistTask) -> some View {
        let selected = selectedChecklistIDs.contains(task.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                if selected {
                    selectedChecklistIDs.remove(task.id)
                } else {
                    selectedChecklistIDs.insert(task.id)
                }
                showValidation = false
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

    // MARK: - Shared UI

    private func footerBar(
        title: String,
        enabled: Bool,
        validation: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            if showValidation {
                Text(validation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.errorCoral)
            }
            Button(title, action: action)
                .buttonStyle(PrimaryOrangeButtonStyle())
                .opacity(enabled ? 1 : 0.55)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func rebuildSuggestedTasks(selectAllIfEmpty: Bool) {
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

    private func confirmChecklist() {
        let chosen = workingSuggestedTasks.filter { selectedChecklistIDs.contains($0.id) }
        guard !chosen.isEmpty else {
            withAnimation { showValidation = true }
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            confirmedTasks = applyDescription(to: chosen)
            showValidation = false
        }
    }

    private func applyDescription(to tasks: [BookingChecklistTask]) -> [BookingChecklistTask] {
        let detail = taskDescriptionDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return tasks }
        return tasks.map { task in
            var copy = task
            copy.detailDescription = detail
            return copy
        }
    }

    private func saveTasks() {
        var tasks = confirmedTasks
        if tasks.isEmpty {
            let chosen = workingSuggestedTasks.filter { selectedChecklistIDs.contains($0.id) }
            tasks = applyDescription(to: chosen)
        } else if !taskDescriptionDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tasks = applyDescription(to: tasks)
        }

        guard !tasks.isEmpty else {
            withAnimation { showValidation = true }
            return
        }

        appModel.appendChecklistTasks(to: bookingID, tasks: tasks)
        dismiss()
    }
}

// MARK: - CTA

/// Full-width orange "Add Task" button used on Requested / Booked booking cards.
struct AddTaskCTAButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Add Task")
                .font(.system(size: 16, weight: .bold))
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
