import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    @State private var bookingTab: BookingTab = .requested
    @State private var showEdit = false
    @State private var expandedBookingID: UUID?
    @State private var expandedMemberID: UUID?

    private var profile: UserProfile { appModel.profile }

    private var filteredBookings: [Booking] {
        appModel.bookings.filter { $0.status.tab == bookingTab }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if profile.isFilled {
                        filledContent
                    } else {
                        emptyContent
                    }
                }
                .padding(20)
                .animation(.easeInOut(duration: 0.25), value: profile.isFilled)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEdit = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .navigationDestination(isPresented: $showEdit) {
                ProfileDetailEditView(profile: editingSeed)
            }
        }
    }

    /// Seed edit form: empty start, or current draft; first open can start blank / partial.
    private var editingSeed: UserProfile {
        var seed = profile
        if !seed.isPublished && seed.firstName.isEmpty {
            // Leave empty so user builds from empty → filled (screen sequence)
            seed.languages = []
            seed.familyMembers = []
        }
        return seed
    }

    // MARK: - Empty state (screen 1)

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            emptyPhotoSection
            accountPill(title: "Admin Account")
            emptySetupFields
            bookingsSection(showRichCards: false)
        }
    }

    private var emptyPhotoSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Circle()
                .fill(Color(red: 0.969, green: 0.957, blue: 0.980))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.grayscale60)
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Profile Photo")
                    .font(.headline)
                Text("Min 400x400px, PNG or JPG formats.")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.349, green: 0.255, blue: 0.451))

                Button {
                    showEdit = true
                } label: {
                    Text("Upload Image")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(red: 0.349, green: 0.255, blue: 0.451))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.918, green: 0.906, blue: 0.933), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var emptySetupFields: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                setupField(title: "Location", placeholder: "Set up your Location") {
                    showEdit = true
                }
                setupField(title: "Services Requested for", placeholder: "Set up your preference") {
                    showEdit = true
                }
                setupField(title: "Contact info", placeholder: "Set up your Contact info") {
                    showEdit = true
                }
                setupField(title: "Payment Method", placeholder: "Set up your Payment info") {}
            }
        }
    }

    // MARK: - Filled state (screen 5)

    private var filledContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            filledHeader
            accountPill(title: profile.accountType)
            filledInfoRow
            bookingsSection(showRichCards: true)
            filledLanguageSection
            filledFamilySection
        }
    }

    private var filledHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("katieAvatar")
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(profile.displayFirstLast.isEmpty ? "Katie Smith" : profile.displayFirstLast)
                        .font(.title3.weight(.semibold))
                    Image("verifiedBadge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }

                Text(profile.roleLabel)
                    .font(.subheadline)
                    .foregroundStyle(Theme.grayscale70)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.brandOrange)
                    Text(String(format: "%.1f", profile.rating))
                        .font(.subheadline.weight(.semibold))
                    Text("(\(profile.reviewCount) reviews)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var filledInfoRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                setupField(
                    title: "Location",
                    placeholder: profile.address.isEmpty ? "12345 street, Seattle, WA" : profile.address
                ) { showEdit = true }
                setupField(
                    title: "Services Requested for",
                    placeholder: profile.servicesRequestedFor.isEmpty
                        ? "mother, father, aunt, child"
                        : profile.servicesRequestedFor
                ) { showEdit = true }
                setupField(
                    title: "Contact",
                    placeholder: profile.mobile.isEmpty
                        ? (profile.email.isEmpty ? "Add contact" : profile.email)
                        : profile.mobile
                ) { showEdit = true }
            }
        }
    }

    private var filledLanguageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Language Preference")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(red: 0.224, green: 0.263, blue: 0.369))

            Text("Language")
                .font(.caption)
                .foregroundStyle(Theme.grayscale70)

            HStack(spacing: 8) {
                ForEach(profile.languages, id: \.self) { language in
                    Text(language)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                Button { showEdit = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.grayscale60)
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.941, green: 0.941, blue: 0.941))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filledFamilySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Family & Friends")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(red: 0.224, green: 0.263, blue: 0.369))

            Text("Member List")
                .font(.subheadline)
                .foregroundStyle(Theme.grayscale70)

            ForEach(profile.familyMembers) { member in
                filledMemberRow(member)
            }

            Button { showEdit = true } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color(red: 0.902, green: 0.910, blue: 0.925), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                        Text("+")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.412, green: 0.412, blue: 0.455))
                    }
                    Text("Adding member")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func filledMemberRow(_ member: FamilyMember) -> some View {
        let expanded = expandedMemberID == member.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(member.avatarStyle.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(member.monogram)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        expandedMemberID = expanded ? nil : member.id
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(member.displayName)
                            .font(.body.weight(.semibold))
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.grayscale60)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }

            if expanded {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred Service")
                            .font(.caption)
                            .foregroundStyle(Theme.grayscale70)
                        ForEach(member.preferredServices, id: \.self) { Text($0).font(.subheadline) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle().fill(Color(.separator)).frame(width: 1).padding(.horizontal, 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred time")
                            .font(.caption)
                            .foregroundStyle(Theme.grayscale70)
                        ForEach(member.preferredTimes, id: \.self) { time in
                            HStack(spacing: 6) {
                                Image(systemName: "clock").font(.caption).foregroundStyle(Theme.grayscale60)
                                Text(time).font(.subheadline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Shared

    private func accountPill(title: String) -> some View {
        HStack {
            Image(systemName: "person.crop.square.fill")
                .foregroundStyle(.green)
            Text(title)
                .foregroundStyle(Color(red: 0.467, green: 0.494, blue: 0.565))
            Spacer()
            Image(systemName: "info.circle")
                .foregroundStyle(Color(red: 0.216, green: 0.490, blue: 1.0))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.profilePill)
        .clipShape(Capsule())
    }

    private func setupField(title: String, placeholder: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.447, green: 0.478, blue: 0.565))
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(Color(red: 0.349, green: 0.255, blue: 0.451))
                    .lineLimit(1)
                    .frame(width: 180, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.941, green: 0.941, blue: 0.941), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    private func bookingsSection(showRichCards: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bookings")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.224, green: 0.263, blue: 0.369))

            Picker("Bookings", selection: $bookingTab) {
                ForEach(BookingTab.allCases) { tab in
                    Text(profile.isFilled ? tab.shortTitle : tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            if filteredBookings.isEmpty {
                emptyBookingsState
            } else if showRichCards {
                ForEach(filteredBookings) { booking in
                    richBookingCard(booking)
                }
            } else {
                ForEach(filteredBookings) { booking in
                    simpleBookingRow(booking)
                }
            }
        }
    }

    private var emptyBookingsState: some View {
        VStack(spacing: 18) {
            Image("emptyBookings")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("No booking \(bookingTab.rawValue)!")
                .font(.title3.weight(.bold))

            Text(emptySubtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.435, green: 0.463, blue: 0.494))
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

    private func simpleBookingRow(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(booking.provider.name).font(.headline)
            Text(booking.provider.title).font(.subheadline).foregroundStyle(.secondary)
            Text(booking.date, style: .date).font(.subheadline)
            Text("\(booking.durationMinutes) min · \(booking.status.rawValue.capitalized)")
                .font(.caption)
                .foregroundStyle(Theme.brandOrange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func richBookingCard(_ booking: Booking) -> some View {
        let isExpanded = expandedBookingID == booking.id
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    expandedBookingID = isExpanded ? nil : booking.id
                }
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.70))
                    Text(booking.status.rawValue.capitalized)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
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
                richBookingDetails(booking)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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

    private func richBookingDetails(_ booking: Booking) -> some View {
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
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(Theme.brandOrange)
                        Text(String(format: "%.1f", booking.provider.rating))
                            .font(.caption.weight(.semibold))
                        Text("(\(booking.provider.reviewCount) reviews)")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)
                    }
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
                labelCard(icon: "calendar", title: booking.date.formatted(.dateTime.day().month().year()))
                labelCard(
                    icon: "clock",
                    title: durationLabel(booking.durationMinutes),
                    subtitle: "Start at \(booking.startTime.formatted(date: .omitted, time: .shortened))\nEnd at \(booking.endTime.formatted(date: .omitted, time: .shortened))"
                )
            }

            HStack(spacing: 12) {
                Button("Cancel") {}
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Menu {
                    Button("Reschedule") {}
                    Button("Edit details") {}
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

            if !booking.serviceProvidedTo.isEmpty {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(Theme.grayscale60)
                    Text("Service provided to \(booking.serviceProvidedTo)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.grayscale70)
                }
            }

            HStack {
                Text("Checklist Details")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.grayscale60)
            }
            .foregroundStyle(Theme.darkText)
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return "\(minutes) min"
    }

    private func labelCard(icon: String, title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.brandOrange)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.grayscale70)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
