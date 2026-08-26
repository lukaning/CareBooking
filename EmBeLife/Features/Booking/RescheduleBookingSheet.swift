import SwiftUI

/// Multi-step reschedule: pick date/time → review → submit proposal.
struct RescheduleBookingSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let booking: Booking

    enum Step: Int {
        case pick
        case review
        case success
    }

    enum Field: Hashable {
        case date, time
    }

    @State private var step: Step = .pick
    @State private var selectedField: Field = .date
    @State private var selectedDate: Date
    @State private var selectedStartTime: Date
    @State private var selectedSlotIndex: Int
    @State private var reason = ""
    @State private var message = ""

    private let timeSlots: [Date]
    private let linkBlue = Theme.linkBlue
    private let fieldLabel = Color(red: 0.10, green: 0.20, blue: 0.45)
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let cardFill = Color(red: 0.97, green: 0.975, blue: 0.985)

    init(booking: Booking) {
        self.booking = booking
        _selectedDate = State(initialValue: booking.date)
        _selectedStartTime = State(initialValue: booking.startTime)

        let calendar = Calendar.current
        let baseDay = calendar.startOfDay(for: booking.date)
        // Half-hour slots from 8:00 AM through 8:00 PM
        let slots: [Date] = (0..<25).compactMap { index in
            calendar.date(bySettingHour: 8 + index / 2, minute: (index % 2) * 30, second: 0, of: baseDay)
        }
        timeSlots = slots

        let bookingHour = calendar.component(.hour, from: booking.startTime)
        let bookingMinute = calendar.component(.minute, from: booking.startTime)
        let index = slots.firstIndex {
            calendar.component(.hour, from: $0) == bookingHour
                && calendar.component(.minute, from: $0) == bookingMinute
        } ?? 2
        _selectedSlotIndex = State(initialValue: index)
    }

    private var proposedStart: Date {
        merge(date: selectedDate, time: selectedStartTime)
    }

    private var proposedEnd: Date {
        proposedStart.addingTimeInterval(TimeInterval(booking.durationMinutes * 60))
    }

    private var canSubmit: Bool {
        proposedStart > Date()
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
                    case .pick:
                        pickStep
                    case .review:
                        reviewStep
                    case .success:
                        successStep
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
                if step == .pick {
                    Text(booking.provider.name)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var headerTitle: String {
        switch step {
        case .pick: "Propose New Time"
        case .review: "Review Proposal"
        case .success: "Proposal Sent"
        }
    }

    // MARK: - Step 1: Pick date & time

    private var pickStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a day and time in the future you want to propose")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                dateField
                timeField
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
                case .time:
                    timeSlotPicker
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Button("Next") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .review
                }
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var dateField: some View {
        selectionCard(isActive: selectedField == .date) {
            selectedField = .date
        } content: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(linkBlue)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(selectedDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var timeField: some View {
        selectionCard(isActive: selectedField == .time) {
            selectedField = .time
        } content: {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.title3)
                    .foregroundStyle(Theme.mutedText)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(timeRangeLabel(start: proposedStart))
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var timeSlotPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .foregroundStyle(Theme.darkText)
                Spacer()
                Button("Clear") {
                    selectedSlotIndex = 0
                    selectedStartTime = timeSlots[0]
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(linkBlue)
            }
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(timeSlots.indices, id: \.self) { index in
                        let slot = timeSlots[index]
                        let rangeStart = merge(date: selectedDate, time: slot)
                        let isSelected = selectedSlotIndex == index
                        Button {
                            selectedSlotIndex = index
                            selectedStartTime = slot
                        } label: {
                            HStack {
                                Text(timeRangeLabel(start: rangeStart))
                                    .font(.body.weight(isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? linkBlue : Theme.darkText)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(linkBlue)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 4)
                            .background(isSelected ? Color(red: 0.93, green: 0.95, blue: 1.0) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        if index < timeSlots.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Review

    private var reviewStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Confirm the new time before sending it to \(booking.provider.name).")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)

                    comparisonCard(
                        title: "Current appointment",
                        date: booking.date,
                        start: booking.startTime,
                        isNew: false
                    )

                    comparisonCard(
                        title: "Proposed appointment",
                        date: selectedDate,
                        start: proposedStart,
                        isNew: true
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for reschedule (optional)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(fieldLabel)
                        TextField("e.g. Schedule conflict", text: $reason)
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(softBorder, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message to provider (optional)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(fieldLabel)
                        TextField("Add a short note…", text: $message, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(softBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(20)
            }

            VStack(spacing: 10) {
                Button("Submit Proposal") {
                    submitProposal()
                }
                .buttonStyle(PrimaryOrangeButtonStyle())

                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        step = .pick
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func comparisonCard(title: String, date: Date, start: Date, isNew: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isNew ? Theme.brandOrange : Theme.mutedText)

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(isNew ? linkBlue : Theme.mutedText)
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
            }

            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .foregroundStyle(isNew ? linkBlue : Theme.mutedText)
                Text(timeRangeLabel(start: start))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(isNew ? Color(red: 1.0, green: 0.96, blue: 0.93) : cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isNew ? Theme.brandOrange.opacity(0.35) : softBorder, lineWidth: 1)
        )
    }

    // MARK: - Step 3: Success

    private var successStep: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            Image(systemName: "paperplane.circle.fill")
                .font(.scaledSystem(size: 64))
                .foregroundStyle(Theme.brandOrange)

            Text("Reschedule proposal sent!")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.darkText)
                .multilineTextAlignment(.center)

            Text("Your new date and time have been proposed to \(booking.provider.name). You'll be notified once they respond.")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            comparisonCard(
                title: "Proposed appointment",
                date: selectedDate,
                start: proposedStart,
                isNew: true
            )
            .padding(.horizontal, 20)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Helpers

    private func timeRangeLabel(start: Date) -> String {
        let end = start.addingTimeInterval(TimeInterval(booking.durationMinutes * 60))
        return "\(clock(start)) - \(clock(end))"
    }

    private func clock(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func merge(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: parts.hour ?? 12,
            minute: parts.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }

    private func submitProposal() {
        appModel.rescheduleBooking(
            id: booking.id,
            date: selectedDate,
            startTime: proposedStart,
            reason: reason,
            message: message
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            step = .success
        }
    }

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
}
