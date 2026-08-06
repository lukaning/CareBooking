import SwiftUI

/// Booked / bookings inbox, opened from Home top-right entry.
struct BookingsView: View {
    @Environment(AppModel.self) private var appModel

    var initialTab: BookingTab = .booked

    @State private var bookingTab: BookingTab
    @State private var expandedBookingID: UUID?
    @State private var bookingToReschedule: Booking?
    @State private var editBookingID: UUID?

    private let headingColor = Color(red: 0.224, green: 0.263, blue: 0.369)
    private let mutedColor = Color(red: 0.435, green: 0.463, blue: 0.494)

    init(initialTab: BookingTab = .booked) {
        self.initialTab = initialTab
        _bookingTab = State(initialValue: initialTab)
    }

    private var filteredBookings: [Booking] {
        appModel.bookings.filter { $0.status.tab == bookingTab }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Bookings", selection: $bookingTab) {
                    ForEach(BookingTab.allCases) { tab in
                        Text(tab.shortTitle).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if filteredBookings.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredBookings) { booking in
                        bookingCard(booking)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
        .navigationTitle(bookingTab.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appModel.seedBookingsIfNeeded()
        }
        .onChange(of: bookingTab) { _, _ in
            expandedBookingID = filteredBookings.first?.id
        }
        .navigationDestination(item: $editBookingID) { id in
            EditBookingView(bookingID: id)
        }
        .sheet(item: $bookingToReschedule) { booking in
            RescheduleBookingSheet(booking: booking)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image("emptyBookings")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("No booking \(bookingTab.rawValue)!")
                .font(.title3.weight(.bold))
                .foregroundStyle(headingColor)

            Text(emptySubtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(mutedColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(red: 0, green: 0.25, blue: 0.5).opacity(0.04), radius: 14, y: 6)
    }

    private var emptySubtitle: String {
        switch bookingTab {
        case .requested: "You don't have any Request yet"
        case .booked: "You don't have any Booked appointments yet"
        case .completed: "You don't have any Completed bookings yet"
        }
    }

    private func bookingCard(_ booking: Booking) -> some View {
        let isExpanded = expandedBookingID == booking.id

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expandedBookingID = isExpanded ? nil : booking.id
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.70))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.provider.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                        Text(booking.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)
                    }

                    Spacer(minLength: 8)

                    Text(booking.status.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.brandOrange)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.grayscale60)
                }
                .padding(12)
                .background(Color(red: 0.93, green: 0.91, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                bookingDetails(booking)
                    .transition(.opacity)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        .onAppear {
            if expandedBookingID == nil {
                expandedBookingID = booking.id
            }
        }
    }

    private func bookingDetails(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Here is your upcoming appointment with \(booking.provider.name).")
                .font(.subheadline)
                .foregroundStyle(Theme.grayscale70)

            HStack(spacing: 12) {
                Image(booking.provider.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.provider.name).font(.headline)
                    Text(booking.provider.title).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("$\(booking.provider.ratePerHour)/hour")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
            )

            HStack(spacing: 10) {
                detailChip(icon: "calendar", title: booking.date.formatted(.dateTime.day().month().year()))
                detailChip(
                    icon: "clock",
                    title: booking.timeRangeWithDurationLabel
                )
            }

            if booking.status != .completed {
                HStack(spacing: 12) {
                    Button("Cancel") {
                        appModel.cancelBooking(id: booking.id)
                        if expandedBookingID == booking.id {
                            expandedBookingID = nil
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Menu {
                        Button("Reschedule") {
                            bookingToReschedule = booking
                        }
                        Button("Edit booking") {
                            editBookingID = booking.id
                        }
                    } label: {
                        HStack {
                            Text("Modify")
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }

            Button {
                editBookingID = booking.id
            } label: {
                HStack {
                    Text("Checklist Details")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.grayscale60)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.darkText)
        }
    }

    private func detailChip(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Theme.brandOrange)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.darkText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        BookingsView()
    }
    .environment(AppModel())
}
