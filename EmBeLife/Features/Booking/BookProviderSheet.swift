import SwiftUI

struct BookProviderSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let provider: Provider
    var appointmentType: BookingAppointmentType = .inPerson

    enum Field: Hashable {
        case date, start, duration
    }

    @State private var selectedField: Field = .date
    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var startTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now
    @State private var durationMinutes = 30

    private let durations = [30, 60, 90, 120]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                header

                Text("Choose a day and time you want to schedule")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                dateField
                HStack(spacing: 12) {
                    startTimeField
                    durationField
                }

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
                    case .start:
                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    case .duration:
                        Picker("Duration", selection: $durationMinutes) {
                            ForEach(durations, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .frame(maxHeight: 320)

                Spacer(minLength: 0)

                Button("Continue") {
                    let booking = Booking(
                        provider: provider,
                        date: selectedDate,
                        startTime: startTime,
                        durationMinutes: durationMinutes,
                        status: .requested
                    )
                    appModel.addBooking(booking)
                    dismiss()
                }
                .buttonStyle(PrimaryOrangeButtonStyle())
            }
            .padding(20)
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
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.brandOrange)
                .frame(width: 4, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Book a Provider")
                    .font(.title3.weight(.bold))
                Text(provider.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(appointmentType.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.brandOrange)
            }
            Spacer()
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
                        .foregroundStyle(.secondary)
                    Text(selectedDate, format: .dateTime.month(.wide).day().year())
                        .font(.headline)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.linkBlue)
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
                        .foregroundStyle(.secondary)
                    Text(startTime, format: .dateTime.hour().minute())
                        .font(.headline)
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
                        .foregroundStyle(.secondary)
                    Text("\(durationMinutes) min")
                        .font(.headline)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.grayscale70)
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
