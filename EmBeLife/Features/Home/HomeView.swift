import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var filtersExpanded = false
    @State private var activeFilter: HomeFilterCriterion?
    @State private var filterState = HomeFilterState()
    @State private var showSettings = false
    @State private var bookingMenuProviderID: String?
    @State private var bookRequest: BookProviderRequest?
    @State private var listMode: HomeProviderListMode = .yourMatches
    @State private var showListMenu = false
    @State private var showBooked = false
    @State private var reviewProvider: Provider?

    private let expandAnimation = Animation.easeInOut(duration: 0.22)

    private var providers: [Provider] {
        switch listMode {
        case .yourMatches:
            return appModel.providers
        case .savedProviders:
            // Demo: first and last as “saved”
            let all = appModel.providers
            guard all.count > 1 else { return all }
            return [all[0], all[all.count - 1]]
        case .previousProviders:
            let ids = Set(
                appModel.bookings
                    .filter { $0.status == .completed }
                    .map(\.provider.id)
            )
            let previous = appModel.providers.filter { ids.contains($0.id) }
            return previous.isEmpty ? Array(appModel.providers.prefix(1)) : previous
        }
    }

    private var bookedCount: Int {
        appModel.bookings.filter { $0.status == .booked }.count
    }

    var body: some View {
        NavigationStack {
            providerList
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { homeToolbar }
                .navigationDestination(isPresented: $showBooked) {
                    BookingsView(initialTab: .requested)
                }
                .navigationDestination(item: $reviewProvider) { provider in
                    RateAndReviewView(provider: provider)
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    matchesHeader
                }
                .sheet(item: $activeFilter) { criterion in
                    FilterSheet(criterion: criterion, filterState: $filterState)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(item: $bookRequest) { request in
                    BookProviderSheet(
                        provider: request.provider,
                        appointmentType: request.appointmentType
                    )
                }
                .background {
                    if bookingMenuProviderID != nil || showListMenu {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    bookingMenuProviderID = nil
                                    showListMenu = false
                                }
                            }
                    }
                }
                .onAppear {
                    appModel.seedBookingsIfNeeded()
                }
        }
    }

    private var homeToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
                .accessibilityLabel("Settings")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showBooked = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "calendar")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)

                        if bookedCount > 0 {
                            Text(bookedCount > 9 ? "9+" : "\(bookedCount)")
                                .font(.scaledSystem(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, bookedCount > 9 ? 3 : 4)
                                .padding(.vertical, 1)
                                .background(Theme.brandOrange)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -6)
                        }
                    }
                    .frame(width: 32, height: 28)
                }
                .accessibilityLabel("Booked")
                .accessibilityHint("View booked appointments")
            }
        }
    }

    private var providerList: some View {
        ScrollView {
            // LazyVStack ignores sibling zIndex in a way that buries floating Book Now menus
            // under the next card; use a plain stack while a menu is open.
            let cards = ForEach(providers) { provider in
                providerCard(for: provider)
                    .zIndex(bookingMenuProviderID == provider.id ? 1000 : 0)
            }

            Group {
                if bookingMenuProviderID != nil {
                    VStack(spacing: 16) {
                        cards
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        cards
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func providerCard(for provider: Provider) -> some View {
        ProviderCard(
            provider: provider,
            isBookingMenuExpanded: bookingMenuProviderID == provider.id,
            onToggleBookingMenu: {
                withAnimation(expandAnimation) {
                    if bookingMenuProviderID == provider.id {
                        bookingMenuProviderID = nil
                    } else {
                        bookingMenuProviderID = provider.id
                    }
                }
            },
            onSelectAppointmentType: { type in
                withAnimation(expandAnimation) {
                    bookingMenuProviderID = nil
                }
                bookRequest = BookProviderRequest(
                    provider: provider,
                    appointmentType: type
                )
            },
            onRatingTap: {
                reviewProvider = provider
            }
        )
    }

    private var matchesHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                listModePicker
                    .zIndex(2)

                Spacer(minLength: 0)

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(expandAnimation) {
                        showListMenu = false
                        filtersExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(filtersExpanded ? Theme.brandOrange : Theme.darkText)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(filtersExpanded ? Theme.brandOrange.opacity(0.12) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    filtersExpanded
                                        ? Theme.brandOrange.opacity(0.45)
                                        : Color(red: 0.88, green: 0.88, blue: 0.90),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(filtersExpanded ? "Hide filters" : "Show filters")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, filtersExpanded ? 10 : 12)
            // Allow dropdown to paint over content below the header row.
            .zIndex(showListMenu ? 3 : 0)

            if filtersExpanded {
                filterCriteriaBar
                    .transition(.opacity)
                    .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
        // Keep soft edge without clipping the floating list-mode menu.
        .zIndex(showListMenu ? 4 : 0)
        .animation(expandAnimation, value: filtersExpanded)
    }

    private var listModePicker: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) {
                showListMenu.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(listMode.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                    .rotationEffect(.degrees(showListMenu ? 180 : 0))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(listMode.title)
        .accessibilityHint("Choose provider list")
        // Popover floats over content without expanding the header layout.
        .overlay(alignment: .topLeading) {
            if showListMenu {
                listModeMenu
                    .offset(y: 36)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading)))
            }
        }
        .zIndex(showListMenu ? 10 : 0)
    }

    private var listModeMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(HomeProviderListMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        listMode = mode
                        showListMenu = false
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(
                            size: 15,
                            weight: listMode == mode ? .semibold : .regular
                        ))
                        .foregroundStyle(
                            listMode == mode
                                ? Theme.darkText
                                : Color(red: 0.45, green: 0.48, blue: 0.55)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background {
                            if listMode == mode {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(red: 0.94, green: 0.95, blue: 0.96))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(width: 188, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        .compositingGroup()
    }

    private var filterCriteriaBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeFilterCriterion.allCases) { criterion in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        activeFilter = criterion
                    } label: {
                        FilterCriterionChip(
                            criterion: criterion,
                            summary: filterState.chipSummary(for: criterion)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Filter criteria

enum HomeProviderListMode: String, CaseIterable, Identifiable {
    case yourMatches
    case savedProviders
    case previousProviders

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yourMatches: "Your Matches"
        case .savedProviders: "Saved Providers"
        case .previousProviders: "Previous Providers"
        }
    }
}

enum HomeFilterCriterion: String, CaseIterable, Identifiable {
    case location
    case typeOfHelp
    case forWho
    case ageRange
    case genderIdentity
    case language
    case priceRange
    case specialNeed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .location: "Location"
        case .typeOfHelp: "Type of Help"
        case .forWho: "For Who"
        case .ageRange: "Age Range"
        case .genderIdentity: "Gender Identity"
        case .language: "Language"
        case .priceRange: "Price Range"
        case .specialNeed: "Special need"
        }
    }

    var shortTitle: String { label }

    var systemImage: String {
        switch self {
        case .location: "safari"
        case .typeOfHelp: "handshake"
        case .forWho: "leaf.fill"
        case .ageRange: "megaphone.fill"
        case .genderIdentity: "person.2.fill"
        case .language: "globe"
        case .priceRange: "tag.fill"
        case .specialNeed: "briefcase.fill"
        }
    }
}

struct HomeFilterState: Equatable {
    var location = "California; Bay Area"
    var typeOfHelp = "Child Care"
    var forWho = "Child"
    var careRecipientAgeGroup = "3-5"
    var ageRanges: [String] = ["25-30", "30-35"]
    var genderIdentity = "Female"
    var languages: [String] = ["English"]
    var minPrice = 15.0
    var maxPrice = 30.0
    var specialNeed = "AD&D"

    func chipSummary(for criterion: HomeFilterCriterion) -> String {
        switch criterion {
        case .location:
            return "in \(location)"
        case .typeOfHelp:
            return typeOfHelp
        case .forWho:
            return "\(forWho); Age Group: \(careRecipientAgeGroup)"
        case .ageRange:
            return ageRanges.joined(separator: "; ")
        case .genderIdentity:
            return genderIdentity
        case .language:
            return languages.isEmpty ? "Any" : languages.joined(separator: "; ")
        case .priceRange:
            return "$\(Int(minPrice)) - $\(Int(maxPrice))"
        case .specialNeed:
            return specialNeed
        }
    }
}

private struct FilterCriterionChip: View {
    let criterion: HomeFilterCriterion
    let summary: String

    private let fill = Color.white
    private let valueColor = Color(red: 0.45, green: 0.50, blue: 0.58)
    private let border = Color(red: 0.90, green: 0.91, blue: 0.93)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: criterion.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            HStack(spacing: 4) {
                Text("\(criterion.label):")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                Text(summary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.darkText.opacity(0.75))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - Provider card

enum BookingAppointmentType: String, Hashable {
    case inPerson
    case video

    var title: String {
        switch self {
        case .inPerson: "In-person Appointment"
        case .video: "Video Appointment"
        }
    }
}

struct BookProviderRequest: Identifiable {
    let id = UUID()
    let provider: Provider
    let appointmentType: BookingAppointmentType
}

struct ProviderCard: View {
    let provider: Provider
    var isBookingMenuExpanded: Bool
    var onToggleBookingMenu: () -> Void
    var onSelectAppointmentType: (BookingAppointmentType) -> Void
    var onRatingTap: () -> Void

    private let menuBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let toggleAnimation = Animation.easeInOut(duration: 0.15)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(provider.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(provider.name)
                        .font(.headline)

                    HStack {
                        Text(provider.title)
                            .font(.subheadline)
                            .foregroundStyle(Theme.darkText)
                        Spacer()
                        Text("$\(provider.ratePerHour)/hour")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            Divider()

            (Text(provider.bio).font(.body).foregroundStyle(Theme.darkText)
                + Text(" ").font(.body)
                + Text("More details").font(.body.weight(.bold)).foregroundStyle(Color.accentColor))

            Text(provider.specialties)
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .lineLimit(1)

            HStack(spacing: 12) {
                iconButton(systemName: "ellipsis")
                // FaceTime-style video marker — not a red YouTube-like play rectangle
                iconButton(systemName: "video.fill", tint: Theme.linkBlue)
                bookNowButton
            }
            .zIndex(isBookingMenuExpanded ? 20 : 0)

            Divider()

            Button(action: onRatingTap) {
                HStack {
                    ProviderRatingLabel(
                        rating: provider.rating,
                        reviewCount: provider.reviewCount
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reviews")
            .accessibilityHint("View provider reviews")
        }
        .padding(16)
        // Avoid clipShape so the floating menu can hang over content below.
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        )
        // Do not use compositingGroup — it flattens/clips the overflow menu under the next card.
        .zIndex(isBookingMenuExpanded ? 1000 : 0)
    }

    private var bookNowButton: some View {
        Button {
            withAnimation(toggleAnimation) {
                onToggleBookingMenu()
            }
        } label: {
            Text("Book Now")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.brandOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Book Now")
        .accessibilityHint(isBookingMenuExpanded ? "Hide booking options" : "Show booking options")
        // Overlay paints above siblings; background was stacking under the next card.
        .overlay(alignment: .topTrailing) {
            if isBookingMenuExpanded {
                bookingTypeMenu
                    .padding(.top, 54)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 220)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
            }
        }
        .zIndex(isBookingMenuExpanded ? 30 : 0)
    }

    private var bookingTypeMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            bookingTypeButton(
                title: "Book an in-person Appointment",
                type: .inPerson
            )

            Divider()
                .background(menuBorder)
                .padding(.leading, 14)

            bookingTypeButton(
                title: "Book a Video Appointment",
                type: .video
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(menuBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        .compositingGroup()
    }

    private func bookingTypeButton(title: String, type: BookingAppointmentType) -> some View {
        Button {
            withAnimation(toggleAnimation) {
                onSelectAppointmentType(type)
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.darkText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func iconButton(systemName: String, tint: Color = Theme.darkText) -> some View {
        Button {} label: {
            Image(systemName: systemName)
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.878, green: 0.878, blue: 0.878), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter screens

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    var criterion: HomeFilterCriterion = .location
    @Binding var filterState: HomeFilterState

    @State private var draft: HomeFilterState
    @State private var minRateText: String
    @State private var maxRateText: String

    private let priceBounds: ClosedRange<Double> = 15...150
    private let priceStep: Double = 1

    private let locationOptions = [
        "California; Bay Area",
        "California; Los Angeles",
        "New York; NYC",
        "Texas; Austin",
        "Remote only"
    ]
    private let typeOfHelpOptions = [
        "Child Care",
        "Personal Care",
        "Postpartum",
        "Companionship",
        "Special Needs",
        "Respite Care"
    ]
    private let forWhoOptions = ["Child", "Parent", "Spouse", "Self", "Other Family"]
    private let careAgeGroupOptions = ["0-2", "3-5", "6-12", "13-17", "18+", "Senior"]
    private let ageRangeOptions = ["18-25", "25-30", "30-35", "35-45", "45-55", "55+"]
    private let genderOptions = ["Any", "Female", "Male", "Non-binary", "Prefer not to say"]
    private let languageOptions = ["English", "Spanish", "Mandarin", "Cantonese", "French", "ASL"]
    private let specialNeedOptions = [
        "None",
        "AD&D",
        "Mobility support",
        "Cognitive support",
        "Sensory support",
        "Medical monitoring"
    ]

    init(criterion: HomeFilterCriterion, filterState: Binding<HomeFilterState>) {
        self.criterion = criterion
        _filterState = filterState
        let initial = filterState.wrappedValue
        _draft = State(initialValue: initial)
        _minRateText = State(initialValue: String(Int(initial.minPrice.rounded())))
        _maxRateText = State(initialValue: String(Int(initial.maxPrice.rounded())))
    }

    var body: some View {
        NavigationStack {
            Form {
                switch criterion {
                case .location:
                    Section("Location") {
                        Picker("Area", selection: $draft.location) {
                            ForEach(locationOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
                    }
                case .typeOfHelp:
                    Section("Type of Help") {
                        Picker("Help type", selection: $draft.typeOfHelp) {
                            ForEach(typeOfHelpOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
                    }
                case .forWho:
                    Section("Recipient") {
                        Picker("For who", selection: $draft.forWho) {
                            ForEach(forWhoOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
                    }
                    Section("Age group") {
                        Picker("Age group", selection: $draft.careRecipientAgeGroup) {
                            ForEach(careAgeGroupOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
                    }
                case .ageRange:
                    Section("Provider age range") {
                        ForEach(ageRangeOptions, id: \.self) { range in
                            Button {
                                toggleAgeRange(range)
                            } label: {
                                HStack {
                                    Text(range)
                                        .foregroundStyle(Theme.darkText)
                                    Spacer()
                                    if draft.ageRanges.contains(range) {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(Theme.brandOrange)
                                    }
                                }
                            }
                        }
                    }
                case .genderIdentity:
                    Section("Gender Identity") {
                        Picker("Gender", selection: $draft.genderIdentity) {
                            ForEach(genderOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
                    }
                case .language:
                    Section {
                        ForEach(languageOptions, id: \.self) { language in
                            Button {
                                toggleLanguage(language)
                            } label: {
                                HStack {
                                    Text(language)
                                        .foregroundStyle(Theme.darkText)
                                    Spacer()
                                    if draft.languages.contains(language) {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(Theme.brandOrange)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Languages")
                    } footer: {
                        Text("Select one or more languages. Currently selected: \(draft.languages.isEmpty ? "none" : draft.languages.joined(separator: ", ")).")
                    }
                case .priceRange:
                    priceFilterSection
                case .specialNeed:
                    Section("Special need") {
                        Picker("Need", selection: $draft.specialNeed) {
                            ForEach(specialNeedOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
                    }
                }
            }
            .navigationTitle(criterion.shortTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if criterion == .priceRange {
                            commitMinRateText()
                            commitMaxRateText()
                        }
                        if draft.ageRanges.isEmpty {
                            draft.ageRanges = ["25-30"]
                        }
                        if draft.languages.isEmpty {
                            draft.languages = ["English"]
                        }
                        filterState = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                if criterion == .priceRange {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            commitMinRateText()
                            commitMaxRateText()
                            hideKeyboard()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func toggleAgeRange(_ range: String) {
        if let index = draft.ageRanges.firstIndex(of: range) {
            draft.ageRanges.remove(at: index)
        } else {
            draft.ageRanges.append(range)
            draft.ageRanges.sort { lhs, rhs in
                (ageRangeOptions.firstIndex(of: lhs) ?? 0) < (ageRangeOptions.firstIndex(of: rhs) ?? 0)
            }
        }
    }

    private func toggleLanguage(_ language: String) {
        if let index = draft.languages.firstIndex(of: language) {
            draft.languages.remove(at: index)
        } else {
            draft.languages.append(language)
            draft.languages.sort { lhs, rhs in
                (languageOptions.firstIndex(of: lhs) ?? 0) < (languageOptions.firstIndex(of: rhs) ?? 0)
            }
        }
    }

    private var priceFilterSection: some View {
        Section {
            DualRangeSlider(
                minValue: $draft.minPrice,
                maxValue: $draft.maxPrice,
                bounds: priceBounds,
                step: priceStep
            )
            .padding(.vertical, 8)
            .onChange(of: draft.minPrice) { _, value in
                minRateText = String(Int(value.rounded()))
            }
            .onChange(of: draft.maxPrice) { _, value in
                maxRateText = String(Int(value.rounded()))
            }

            HStack(alignment: .top, spacing: 12) {
                priceNumberField(
                    title: "Min ($/hr)",
                    text: $minRateText,
                    onCommit: commitMinRateText
                )
                priceNumberField(
                    title: "Max ($/hr)",
                    text: $maxRateText,
                    onCommit: commitMaxRateText
                )
            }

            Text("Showing $\(Int(draft.minPrice)) – $\(Int(draft.maxPrice))/hour")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.brandOrange)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        } header: {
            Text("Hourly rate")
        } footer: {
            Text("Drag either handle to set a range, or type an exact min and max rate.")
        }
    }

    private func priceNumberField(
        title: String,
        text: Binding<String>,
        onCommit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.mutedText)

            HStack(spacing: 4) {
                Text("$")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue {
                            text.wrappedValue = filtered
                        }
                    }
                    .onSubmit(onCommit)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commitMinRateText() {
        let parsed = Double(minRateText) ?? draft.minPrice
        let clamped = min(max(parsed, priceBounds.lowerBound), draft.maxPrice)
        draft.minPrice = clamped
        minRateText = String(Int(clamped.rounded()))
    }

    private func commitMaxRateText() {
        let parsed = Double(maxRateText) ?? draft.maxPrice
        let clamped = max(min(parsed, priceBounds.upperBound), draft.minPrice)
        draft.maxPrice = clamped
        maxRateText = String(Int(clamped.rounded()))
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Dual range slider

private struct DualRangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    var step: Double = 1

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 28
    private let activeTrack = Theme.brandOrange
    private let inactiveTrack = Color(red: 0.88, green: 0.89, blue: 0.91)

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let width = max(geo.size.width, 1)
                let minX = xPosition(for: minValue, width: width)
                let maxX = xPosition(for: maxValue, width: width)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(inactiveTrack)
                        .frame(height: trackHeight)

                    Capsule()
                        .fill(activeTrack)
                        .frame(width: max(maxX - minX, 0), height: trackHeight)
                        .offset(x: minX)

                    thumb(isMin: true, x: minX, width: width)
                    thumb(isMin: false, x: maxX, width: width)
                }
                .frame(height: thumbSize)
                .contentShape(Rectangle())
            }
            .frame(height: thumbSize)

            HStack {
                Text("$\(Int(bounds.lowerBound))")
                Spacer()
                Text("$\(Int(bounds.upperBound))")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.mutedText)
        }
    }

    private func thumb(isMin: Bool, x: CGFloat, width: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            .overlay(
                Circle()
                    .stroke(activeTrack, lineWidth: 2)
            )
            .overlay(
                Circle()
                    .fill(activeTrack.opacity(0.15))
                    .frame(width: 10, height: 10)
            )
            .offset(x: x - thumbSize / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let raw = value(for: drag.location.x, width: width)
                        if isMin {
                            minValue = min(snap(raw), maxValue)
                        } else {
                            maxValue = max(snap(raw), minValue)
                        }
                    }
            )
            .accessibilityLabel(isMin ? "Minimum rate" : "Maximum rate")
            .accessibilityValue("$\(Int(isMin ? minValue : maxValue)) per hour")
    }

    private func xPosition(for value: Double, width: CGFloat) -> CGFloat {
        let span = bounds.upperBound - bounds.lowerBound
        guard span > 0 else { return 0 }
        let ratio = (value - bounds.lowerBound) / span
        return CGFloat(ratio) * width
    }

    private func value(for x: CGFloat, width: CGFloat) -> Double {
        let clampedX = min(max(x, 0), width)
        let ratio = Double(clampedX / width)
        let span = bounds.upperBound - bounds.lowerBound
        return bounds.lowerBound + ratio * span
    }

    private func snap(_ value: Double) -> Double {
        let stepped = (value / step).rounded() * step
        return min(max(stepped, bounds.lowerBound), bounds.upperBound)
    }
}
