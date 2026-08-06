import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var filtersExpanded = false
    @State private var activeFilter: HomeFilterCriterion?
    @State private var filterState = HomeFilterState()
    @State private var showSettings = false
    @State private var pendingBookProvider: Provider?
    @State private var bookRequest: BookProviderRequest?
    @State private var sortNewest = true
    @State private var showBooked = false

    private let expandAnimation = Animation.easeInOut(duration: 0.22)

    private var providers: [Provider] {
        sortNewest ? appModel.providers : appModel.providers.reversed()
    }

    private var bookedCount: Int {
        appModel.bookings.filter { $0.status == .booked }.count
    }

    private var showBookingTypeSheet: Binding<Bool> {
        Binding(
            get: { pendingBookProvider != nil },
            set: { if !$0 { pendingBookProvider = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(providers) { provider in
                        ProviderCard(provider: provider) {
                            pendingBookProvider = provider
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                                    .font(.system(size: 9, weight: .bold))
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
            .navigationDestination(isPresented: $showBooked) {
                BookingsView(initialTab: .booked)
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
            .confirmationDialog(
                "",
                isPresented: showBookingTypeSheet,
                titleVisibility: .hidden
            ) {
                Button("Book an in-person Appointment") {
                    openBooking(type: .inPerson)
                }
                Button("Book a Video Appointment") {
                    openBooking(type: .video)
                }
                Button("Cancel", role: .cancel) {
                    pendingBookProvider = nil
                }
            }
            .sheet(item: $bookRequest) { request in
                BookProviderSheet(
                    provider: request.provider,
                    appointmentType: request.appointmentType
                )
            }
            .onAppear {
                appModel.seedBookingsIfNeeded()
            }
        }
    }

    private func openBooking(type: BookingAppointmentType) {
        guard let provider = pendingBookProvider else { return }
        pendingBookProvider = nil
        // Let the action sheet finish dismissing before presenting the sheet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            bookRequest = BookProviderRequest(provider: provider, appointmentType: type)
        }
    }

    private var matchesHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Menu {
                    Button(sortNewest ? "Newest first ✓" : "Newest first") {
                        sortNewest = true
                    }
                    Button(!sortNewest ? "Highest rated ✓" : "Highest rated") {
                        sortNewest = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Your Matches")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(expandAnimation) {
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

            if filtersExpanded {
                filterCriteriaBar
                    .transition(.opacity)
                    .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
        .animation(expandAnimation, value: filtersExpanded)
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
    var language = "English"
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
            return language
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
    var onBook: () -> Void

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

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Theme.brandOrange)
                            .font(.caption)
                        Text(String(format: "%.1f", provider.rating))
                            .font(.subheadline.weight(.semibold))
                        Text("(\(provider.reviewCount) reviews)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedText)
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
                iconButton(systemName: "play.rectangle.fill", tint: .red)

                Button("Book Now", action: onBook)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.brandOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Divider()

            HStack {
                Text("\(provider.bookingCount) of bookings")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.mutedText)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
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
                    Section("Language") {
                        Picker("Language", selection: $draft.language) {
                            ForEach(languageOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.inline)
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
