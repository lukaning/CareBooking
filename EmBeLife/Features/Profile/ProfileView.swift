import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    /// When false, content is pushed inside an existing NavigationStack (e.g. Settings).
    var embedsNavigation: Bool = true

    @State private var bookingTab: BookingTab = .requested
    @State private var showEdit = false
    @State private var expandedBookingID: UUID?
    @State private var expandedMemberID: UUID?
    @State private var bookingToReschedule: Booking?
    @State private var bookingRoute: BookingRoute?
    @State private var showPayReceive = false
    @State private var reviewProvider: Provider?
    @State private var reviewingBookingID: UUID?
    @State private var draftRatings: [UUID: Int] = [:]
    @State private var draftTexts: [UUID: String] = [:]

    private var profile: UserProfile { appModel.profile }

    private var filteredBookings: [Booking] {
        appModel.bookings.filter { $0.status.tab == bookingTab }
    }

    // MARK: - Design tokens (profile filled state)

    private let pageBG = Color.white
    private let sectionTitle = Color(red: 0.22, green: 0.26, blue: 0.36)
    private let labelMuted = Color(red: 0.45, green: 0.48, blue: 0.56)
    private let bodyDark = Color(red: 0.12, green: 0.14, blue: 0.18)
    private let softCard = Color(red: 0.945, green: 0.952, blue: 0.965)
    private let fieldValue = Color(red: 0.15, green: 0.16, blue: 0.20)
    private let giftScanTint = Color(red: 0.62, green: 0.52, blue: 0.88)
    private let purpleAccent = Color(red: 0.48, green: 0.42, blue: 0.78)
    private let tabDot = Color(red: 0.35, green: 0.55, blue: 0.95)
    private let cancelFill = Color(red: 0.91, green: 0.92, blue: 0.94)
    private let borderLight = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let modalCardBG = Color(red: 0.965, green: 0.968, blue: 0.975)
    private let iconMuted = Color(red: 0.42, green: 0.45, blue: 0.52)
    private let cardShadow = Color.black.opacity(0.06)
    private let pagePadding: CGFloat = 16
    private let sectionSpacing: CGFloat = 22

    var body: some View {
        Group {
            if embedsNavigation {
                NavigationStack {
                    profileRoot
                }
            } else {
                profileRoot
            }
        }
    }

    private var profileRoot: some View {
        ScrollView {
            Group {
                if profile.isFilled {
                    filledContent
                } else {
                    emptyContent
                }
            }
            .padding(.horizontal, pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .animation(.easeInOut(duration: 0.25), value: profile.isFilled)
        }
        .background(pageBG)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(bodyDark)
                }
                .accessibilityLabel("Edit profile")
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            ProfileDetailEditView(profile: editingSeed)
        }
        .navigationDestination(isPresented: $showPayReceive) {
            PayReceiveView()
        }
        .navigationDestination(item: $reviewProvider) { provider in
            RateAndReviewView(provider: provider)
        }
        .navigationDestination(item: $bookingRoute) { route in
            EditBookingView(bookingID: route.id)
        }
        .sheet(item: $bookingToReschedule) { booking in
            RescheduleBookingSheet(booking: booking)
        }
        .onAppear {
            appModel.seedBookingsIfNeeded()
            if expandedMemberID == nil {
                expandedMemberID = profile.familyMembers.first?.id
            }
        }
    }

    private var editingSeed: UserProfile {
        var seed = profile
        if !seed.isPublished && seed.firstName.isEmpty {
            seed.languages = []
            seed.familyMembers = []
        }
        return seed
    }

    // MARK: - Empty state

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(bodyDark)
                Text("Min 400x400px, PNG or JPG formats.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.35, green: 0.26, blue: 0.45))

                Button {
                    showEdit = true
                } label: {
                    Text("Upload Image")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.35, green: 0.26, blue: 0.45))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(red: 0.92, green: 0.91, blue: 0.93), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var emptySetupFields: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                infoField(title: "Location", value: "Set up your Location") { showEdit = true }
                infoField(title: "Services Requested for", value: "Set up your preference") { showEdit = true }
                infoField(title: "Contact info", value: "Set up your Contact info") { showEdit = true }
                infoField(title: "Payment Method", value: "Set up your Payment info") {}
            }
        }
    }

    // MARK: - Filled state

    private var filledContent: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            filledHeader
            accountPill(title: profile.accountType.isEmpty ? "Owner Account" : profile.accountType)
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
                .frame(width: 76, height: 76)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(headerDisplayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(bodyDark)
                        .lineLimit(1)

                    Image("verifiedBadge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }

                Text(profile.roleLabel.isEmpty ? "Customer" : profile.roleLabel)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(labelMuted)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.brandOrange)
                    Text(String(format: "%.1f", profile.rating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(bodyDark)
                    Text("(\(profile.reviewCount) reviews)")
                        .font(.system(size: 14))
                        .foregroundStyle(labelMuted)
                }
            }

            Spacer(minLength: 8)

            // Gift scan entry (in-page; toolbar only has edit pencil)
            Button {
                showPayReceive = true
            } label: {
                Image(systemName: "viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(giftScanTint)
                    .frame(width: 42, height: 42)
                    .background(giftScanTint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pay or receive gifts")
        }
    }

    private var headerDisplayName: String {
        if !profile.firstName.isEmpty { return profile.firstName }
        if !profile.displayFirstLast.isEmpty { return profile.displayFirstLast }
        return "Katie"
    }

    private var filledInfoRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                infoField(
                    title: "Location",
                    value: profile.address.isEmpty ? "12345 street, Seattle, WA" : profile.address
                ) { showEdit = true }
                infoField(
                    title: "Services Requested for",
                    value: profile.servicesRequestedFor.isEmpty
                        ? "mother, father, aunt, child"
                        : profile.servicesRequestedFor
                ) { showEdit = true }
                infoField(
                    title: "Contact",
                    value: profile.mobile.isEmpty
                        ? (profile.email.isEmpty ? "Add contact" : profile.email)
                        : profile.mobile
                ) { showEdit = true }
            }
        }
    }

    private var filledLanguageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language Preference")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(sectionTitle)

            Text("Language")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(labelMuted)

            HStack(spacing: 8) {
                let languages = profile.languages.isEmpty ? ["English", "Spain"] : profile.languages
                ForEach(languages, id: \.self) { language in
                    HStack(spacing: 6) {
                        Text(language)
                            .font(.system(size: 13, weight: .bold))
                        Text("×")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Theme.brandOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                Button { showEdit = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(labelMuted)
                        .frame(width: 34, height: 34)
                        .background(Color(red: 0.94, green: 0.94, blue: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filledFamilySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Family & Friends")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(sectionTitle)

            Text("Member List")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(bodyDark)

            VStack(spacing: 10) {
                ForEach(profile.familyMembers) { member in
                    filledMemberRow(member)
                }
            }

            Button { showEdit = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(borderLight, lineWidth: 1.5)
                            .frame(width: 40, height: 40)
                        Text("+")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(red: 0.41, green: 0.41, blue: 0.46))
                    }
                    Text("Adding member")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(bodyDark)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private func filledMemberRow(_ member: FamilyMember) -> some View {
        let expanded = expandedMemberID == member.id
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(member.avatarStyle.color)
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text(member.monogram)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        expandedMemberID = expanded ? nil : member.id
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(member.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(bodyDark)
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(labelMuted)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.35))
            }

            if expanded {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Service")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(labelMuted)
                        ForEach(member.preferredServices, id: \.self) { service in
                            Text(service)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(bodyDark)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(borderLight)
                        .frame(width: 1)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred time")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(labelMuted)
                        ForEach(member.preferredTimes, id: \.self) { time in
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundStyle(labelMuted)
                                Text(time)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(bodyDark)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderLight, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(softCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Shared chrome

    private func accountPill(title: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.20, green: 0.72, blue: 0.55).opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.15, green: 0.62, blue: 0.48))
                }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.52))

            Spacer()

            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundStyle(Color(red: 0.45, green: 0.48, blue: 0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(softCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func infoField(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(labelMuted)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(fieldValue)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 148, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(borderLight, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bookings

    private func bookingsSection(showRichCards: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bookings")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(sectionTitle)

            bookingTabControl

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

    private var bookingTabControl: some View {
        HStack(spacing: 0) {
            ForEach(BookingTab.allCases) { tab in
                let selected = bookingTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        bookingTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(profile.isFilled ? tab.shortTitle : tab.rawValue)
                            .font(.system(size: 14, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? bodyDark : labelMuted)
                        if selected {
                            Circle()
                                .fill(tabDot)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(softCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyBookingsState: some View {
        VStack(spacing: 16) {
            Image("emptyBookings")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("No booking \(bookingTab.rawValue)!")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(bodyDark)

            Text(emptySubtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(labelMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderLight, lineWidth: 1)
        )
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
            Text(booking.provider.name)
                .font(.system(size: 16, weight: .semibold))
            Text(booking.provider.title)
                .font(.system(size: 14))
                .foregroundStyle(labelMuted)
            Text(booking.date, style: .date)
                .font(.system(size: 14))
            Text("\(booking.durationMinutes) min · \(booking.status.rawValue.capitalized)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.brandOrange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(softCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func richBookingCard(_ booking: Booking) -> some View {
        let isExpanded = expandedBookingID == booking.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    expandedBookingID = isExpanded ? nil : booking.id
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(purpleAccent.opacity(0.85))
                        .frame(width: 5, height: 26)

                    Text(statusTitle(for: booking))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(bodyDark)

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(iconMuted)
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.91, green: 0.92, blue: 0.94))
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, isExpanded ? 8 : 0)

            if isExpanded {
                richBookingDetails(booking)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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

    private func statusTitle(for booking: Booking) -> String {
        switch booking.status {
        case .requested: "Requested"
        case .booked: "Booked"
        case .completed: "Completed"
        }
    }

    private func richBookingDetails(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if booking.status == .completed {
                completedBookingDetails(booking)
            } else {
                activeBookingDetails(booking)
            }
        }
    }

    private func completedBookingDetails(_ booking: Booking) -> some View {
        let isComposing = reviewingBookingID == booking.id

        return VStack(alignment: .leading, spacing: 12) {
            providerMiniCard(booking)

            metaRow(icon: "calendar", text: formattedBookingDate(booking.date))

            if !booking.serviceProvidedTo.isEmpty {
                whiteInsetCard {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(labelMuted)
                        Text("Service provided to \(booking.serviceProvidedTo)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(bodyDark)
                    }
                }
            }

            if booking.hasClientReview {
                whiteInsetCard {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(red: 0.20, green: 0.68, blue: 0.38))
                        Text("You rated \(booking.clientReviewRating ?? 0) stars")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(bodyDark)
                        Spacer()
                        Button("View reviews") {
                            reviewProvider = booking.provider
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.linkBlue)
                    }
                }
            } else if isComposing {
                InlineBookingReviewComposer(
                    rating: Binding(
                        get: { draftRatings[booking.id] ?? 0 },
                        set: { draftRatings[booking.id] = $0 }
                    ),
                    text: Binding(
                        get: { draftTexts[booking.id] ?? "" },
                        set: { draftTexts[booking.id] = $0 }
                    ),
                    onSubmit: {
                        let rating = draftRatings[booking.id] ?? 0
                        let text = draftTexts[booking.id] ?? ""
                        appModel.submitBookingReview(bookingID: booking.id, rating: rating, text: text)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            reviewingBookingID = nil
                        }
                        draftRatings[booking.id] = nil
                        draftTexts[booking.id] = nil
                    }
                )
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        reviewingBookingID = booking.id
                        draftRatings[booking.id] = draftRatings[booking.id] ?? 0
                        draftTexts[booking.id] = draftTexts[booking.id] ?? ""
                    }
                } label: {
                    Text("Add review")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func activeBookingDetails(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Here is your upcoming appointment with \(booking.provider.name)")
                .font(.system(size: 14))
                .foregroundStyle(labelMuted)
                .padding(.bottom, 4)

            providerMiniCard(booking)

            // Date
            floatingCard {
                HStack(spacing: 14) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(iconMuted)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Date")
                            .font(.system(size: 13))
                            .foregroundStyle(labelMuted)
                        Text(formattedBookingDate(booking.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(bodyDark)
                    }
                    Spacer(minLength: 0)
                }
            }

            // Time + Cancel / Modify (actions live inside this card per design)
            floatingCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "clock")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(iconMuted)
                            .frame(width: 26)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time")
                                .font(.system(size: 13))
                                .foregroundStyle(labelMuted)
                            Text(durationLabel(booking.durationMinutes))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(bodyDark)
                            Text("Start at \(clockTime(booking.startTime))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(bodyDark)
                            Text("End at \(clockTime(booking.endTime))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(bodyDark)
                        }
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 12) {
                        Button {
                            appModel.cancelBooking(id: booking.id)
                            if expandedBookingID == booking.id {
                                expandedBookingID = nil
                            }
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(bodyDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(cancelFill)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        modifySplitButton(for: booking)
                    }
                }
            }

            if !booking.serviceProvidedTo.isEmpty {
                floatingCard {
                    HStack(spacing: 14) {
                        Image(systemName: "person.bubble")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(iconMuted)
                            .frame(width: 26)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Services provided to")
                                .font(.system(size: 13))
                                .foregroundStyle(labelMuted)
                            Text(booking.serviceProvidedTo)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(bodyDark)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            Button {
                bookingRoute = BookingRoute(id: booking.id)
            } label: {
                floatingCard {
                    HStack(spacing: 14) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(iconMuted)
                            .frame(width: 26)
                        Text("Checklist Details")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(bodyDark)
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

    private func modifySplitButton(for booking: Booking) -> some View {
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
                    bookingRoute = BookingRoute(id: booking.id)
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

    private func providerMiniCard(_ booking: Booking) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(booking.provider.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.provider.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(bodyDark)
                Text(booking.provider.title)
                    .font(.system(size: 13))
                    .foregroundStyle(labelMuted)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Button {
                        reviewProvider = booking.provider
                    } label: {
                        ProviderRatingLabel(
                            rating: booking.provider.rating,
                            reviewCount: booking.provider.reviewCount,
                            compact: true
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 4)

                    Text("$\(booking.provider.ratePerHour)/hour")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(bodyDark)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: cardShadow, radius: 8, x: 0, y: 3)
    }

    private func metaRow(icon: String, text: String) -> some View {
        floatingCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconMuted)
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(bodyDark)
                Spacer()
            }
        }
    }

    private func whiteInsetCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        floatingCard(content: content)
    }

    private func floatingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: cardShadow, radius: 8, x: 0, y: 3)
    }

    private func formattedBookingDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, yyyy"
        return formatter.string(from: date)
    }

    private func clockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }

    private func timeRangeLine(_ booking: Booking) -> String {
        "\(clockTime(booking.startTime)) - \(clockTime(booking.endTime))"
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

private struct BookingRoute: Identifiable, Hashable {
    let id: UUID
}
