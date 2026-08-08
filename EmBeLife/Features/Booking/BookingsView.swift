import SwiftUI

/// Booked / bookings inbox, opened from Home top-right entry.
struct BookingsView: View {
    @Environment(AppModel.self) private var appModel

    var initialTab: BookingTab = .booked

    @State private var bookingTab: BookingTab
    @State private var expandedBookingID: UUID?
    @State private var bookingToReschedule: Booking?
    @State private var editBookingID: UUID?

    private let headingColor = Color(red: 0.12, green: 0.14, blue: 0.18)
    private let mutedColor = Color(red: 0.45, green: 0.48, blue: 0.56)
    private let iconMuted = Color(red: 0.42, green: 0.45, blue: 0.52)
    private let modalCardBG = Color(red: 0.965, green: 0.968, blue: 0.975)
    private let cancelFill = Color(red: 0.91, green: 0.92, blue: 0.94)
    private let purpleAccent = Color(red: 0.48, green: 0.42, blue: 0.78)
    private let cardShadow = Color.black.opacity(0.06)
    private let segmentTrack = Color(red: 0.94, green: 0.945, blue: 0.955)
    private let segmentInactiveText = Color(red: 0.45, green: 0.51, blue: 0.58)
    private let segmentDivider = Color(red: 0.86, green: 0.88, blue: 0.91)

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
                bookingSegmentControl

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

    private var bookingSegmentControl: some View {
        let tabs = BookingTab.allCases
        return HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                let selected = bookingTab == tab
                let nextSelected = index + 1 < tabs.count && bookingTab == tabs[index + 1]

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        bookingTab = tab
                    }
                } label: {
                    Text(tab.shortTitle)
                        .font(.system(size: 14, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? headingColor : segmentInactiveText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)

                // Divider between inactive neighbors only (hidden next to selected pill)
                if index < tabs.count - 1 {
                    Rectangle()
                        .fill(segmentDivider)
                        .frame(width: 1, height: 16)
                        .opacity(selected || nextSelected ? 0 : 1)
                }
            }
        }
        .padding(4)
        .background(segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
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

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expandedBookingID = isExpanded ? nil : booking.id
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(purpleAccent.opacity(0.85))
                        .frame(width: 5, height: 26)

                    Text(booking.status.rawValue.capitalized)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(headingColor)

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(iconMuted)
                        .frame(width: 32, height: 32)
                        .background(cancelFill)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, isExpanded ? 8 : 0)

            if isExpanded {
                bookingDetails(booking)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(modalCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear {
            if expandedBookingID == nil {
                expandedBookingID = booking.id
            }
        }
    }

    private func bookingDetails(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Here is your upcoming appointment with \(booking.provider.name)")
                .font(.system(size: 14))
                .foregroundStyle(mutedColor)
                .padding(.bottom, 4)

            providerCard(booking)

            floatingCard {
                HStack(spacing: 14) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundStyle(iconMuted)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Date")
                            .font(.system(size: 13))
                            .foregroundStyle(mutedColor)
                        Text(formattedDate(booking.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(headingColor)
                    }
                    Spacer(minLength: 0)
                }
            }

            floatingCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "clock")
                            .font(.system(size: 20))
                            .foregroundStyle(iconMuted)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time")
                                .font(.system(size: 13))
                                .foregroundStyle(mutedColor)
                            Text(durationLabel(booking.durationMinutes))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(headingColor)
                            Text("Start at \(clockTime(booking.startTime))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(headingColor)
                            Text("End at \(clockTime(booking.endTime))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(headingColor)
                        }
                        Spacer(minLength: 0)
                    }

                    if booking.status != .completed {
                        HStack(spacing: 12) {
                            Button {
                                appModel.cancelBooking(id: booking.id)
                                if expandedBookingID == booking.id {
                                    expandedBookingID = nil
                                }
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(headingColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(cancelFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 0) {
                                Button {
                                    bookingToReschedule = booking
                                } label: {
                                    Text("Modify")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                Rectangle()
                                    .fill(Color.white.opacity(0.35))
                                    .frame(width: 1, height: 22)

                                Menu {
                                    Button("Reschedule") {
                                        bookingToReschedule = booking
                                    }
                                    Button("Edit booking") {
                                        editBookingID = booking.id
                                    }
                                    Button("Cancel booking", role: .destructive) {
                                        appModel.cancelBooking(id: booking.id)
                                        if expandedBookingID == booking.id {
                                            expandedBookingID = nil
                                        }
                                    }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 44)
                                        .padding(.vertical, 14)
                                }
                            }
                            .background(Theme.brandOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            if !booking.serviceProvidedTo.isEmpty {
                floatingCard {
                    HStack(spacing: 14) {
                        Image(systemName: "person.bubble")
                            .font(.system(size: 18))
                            .foregroundStyle(iconMuted)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Services provided to")
                                .font(.system(size: 13))
                                .foregroundStyle(mutedColor)
                            Text(booking.serviceProvidedTo)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(headingColor)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            Button {
                editBookingID = booking.id
            } label: {
                floatingCard {
                    HStack(spacing: 14) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 18))
                            .foregroundStyle(iconMuted)
                            .frame(width: 26)
                        Text("Checklist Details")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(headingColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(iconMuted)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func providerCard(_ booking: Booking) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(booking.provider.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.provider.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(headingColor)
                Text(booking.provider.title)
                    .font(.system(size: 13))
                    .foregroundStyle(mutedColor)
                HStack {
                    ProviderRatingLabel(
                        rating: booking.provider.rating,
                        reviewCount: booking.provider.reviewCount,
                        compact: true
                    )
                    Spacer(minLength: 4)
                    Text("$\(booking.provider.ratePerHour)/hour")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(headingColor)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: cardShadow, radius: 8, x: 0, y: 3)
    }

    private func floatingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: cardShadow, radius: 8, x: 0, y: 3)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, yyyy"
        return formatter.string(from: date)
    }

    private func clockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        if minutes > 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            return "\(hours)h \(rem) min"
        }
        return "\(minutes) min"
    }
}

#Preview {
    NavigationStack {
        BookingsView()
    }
    .environment(AppModel())
}
