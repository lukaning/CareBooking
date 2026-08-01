import SwiftUI

struct EditBookingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let bookingID: UUID

    @State private var checklistExpanded = false

    private var booking: Booking? {
        appModel.booking(id: bookingID)
    }

    var body: some View {
        Group {
            if let booking {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection(booking)
                        detailCards(booking)
                        checklistSection(booking)
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView("Booking Not Found", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Edit Booking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
        }
        .navigationBarBackButtonHidden()
    }

    private func headerSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(booking.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(booking.taskDescription)
                    .font(.subheadline)
                    .foregroundStyle(Theme.grayscale60)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Provider")
                        .font(.headline)
                    HStack(spacing: 10) {
                        Image(booking.provider.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        Text(booking.provider.name)
                            .font(.subheadline.weight(.semibold))
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
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.grayscale60)
                        Text(booking.dateCreated, format: .dateTime.month(.abbreviated).day().year())
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func detailCards(_ booking: Booking) -> some View {
        VStack(spacing: 14) {
            detailCard(
                icon: "person.crop.circle",
                label: "Services provided to",
                value: booking.serviceProvidedTo.isEmpty ? "Not specified" : booking.serviceProvidedTo
            )
            detailCard(
                icon: "calendar",
                label: "Date",
                value: booking.date.formatted(.dateTime.day().month(.abbreviated).year())
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

    private func detailCard(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.grayscale70)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.grayscale70)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(red: 0.988, green: 0.988, blue: 0.988))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(red: 0.835, green: 0.835, blue: 0.902).opacity(0.5), radius: 6, y: 4)
    }

    private func checklistSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    checklistExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(Theme.grayscale70)
                    Text("Tasks Checklist")
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                    Spacer()
                    Image(systemName: checklistExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.grayscale60)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if checklistExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Assist with daily activities, engage in gentle physical therapy exercises as recommended by professionals to promote mobility and strength.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale70)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Detailed Checklist below")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.grayscale60)

                    ForEach(booking.checklistTasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.subheadline.weight(.semibold))
                            Text(task.category)
                                .font(.caption)
                                .foregroundStyle(Theme.grayscale60)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button("Add Task") {}
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(red: 0.988, green: 0.988, blue: 0.988))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(red: 0.835, green: 0.835, blue: 0.902).opacity(0.5), radius: 6, y: 4)
    }
}
