import SwiftUI

struct RescheduleBookingSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let booking: Booking

    enum Field: Hashable {
        case date, time
    }

    @State private var selectedField: Field = .date
    @State private var selectedDate: Date
    @State private var selectedStartTime: Date
    @State private var selectedSlotIndex: Int

    private let timeSlots: [Date]

    init(booking: Booking) {
        self.booking = booking
        _selectedDate = State(initialValue: booking.date)
        _selectedStartTime = State(initialValue: booking.startTime)

        let calendar = Calendar.current
        let base = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: booking.date) ?? booking.startTime
        let slots = (0..<6).compactMap { offset in
            calendar.date(byAdding: .hour, value: offset, to: base)
        }
        timeSlots = slots
        let index = slots.firstIndex {
            calendar.component(.hour, from: $0) == calendar.component(.hour, from: booking.startTime)
        } ?? 1
        _selectedSlotIndex = State(initialValue: index)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose a day and time in the future you want to propose")
                    .font(.subheadline)
                    .foregroundStyle(Theme.grayscale70)

                dateField
                timeField

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
                        .tint(Theme.linkBlue)
                    case .time:
                        timeSlotPicker
                    }
                }
                .frame(maxHeight: 360)

                Spacer(minLength: 0)

                Button("Submit Proposal") {
                    let calendar = Calendar.current
                    let slot = timeSlots[selectedSlotIndex]
                    let hour = calendar.component(.hour, from: slot)
                    let minute = calendar.component(.minute, from: slot)
                    let newStart = calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: selectedDate
                    ) ?? slot
                    appModel.rescheduleBooking(id: booking.id, date: selectedDate, startTime: newStart)
                    dismiss()
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
            }
            .padding(20)
            .navigationTitle("Propose New Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: selectedSlotIndex) { _, newIndex in
            selectedStartTime = timeSlots[newIndex]
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
                        .foregroundStyle(Theme.grayscale70)
                    Text(selectedDate, format: .dateTime.month(.wide).day().year())
                        .font(.headline)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.linkBlue)
            }
        }
    }

    private var timeField: some View {
        selectionCard(isActive: selectedField == .time) {
            selectedField = .time
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(Theme.grayscale70)
                    Text(timeRangeLabel)
                        .font(.headline)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.grayscale70)
            }
        }
    }

    private var timeRangeLabel: String {
        let end = selectedStartTime.addingTimeInterval(TimeInterval(booking.durationMinutes * 60))
        let start = selectedStartTime.formatted(date: .omitted, time: .shortened)
        let endStr = end.formatted(date: .omitted, time: .shortened)
        return "\(start) - \(endStr)"
    }

    private var timeSlotPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selectedStartTime, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(timeSlots.indices, id: \.self) { index in
                        let slot = timeSlots[index]
                        let end = slot.addingTimeInterval(TimeInterval(booking.durationMinutes * 60))
                        Button {
                            selectedSlotIndex = index
                            selectedStartTime = slot
                        } label: {
                            HStack {
                                Text("\(slot.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))")
                                    .font(.body.weight(selectedSlotIndex == index ? .semibold : .regular))
                                    .foregroundStyle(selectedSlotIndex == index ? Theme.linkBlue : .primary)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 4)
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
                        .stroke(isActive ? Theme.linkBlue : Color(.separator), lineWidth: isActive ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
