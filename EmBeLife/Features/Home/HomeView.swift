import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var filtersExpanded = false
    @State private var activeFilter: HomeFilterCriterion?
    @State private var showSettings = false
    @State private var bookingProvider: Provider?
    @State private var sortNewest = true
    @State private var showBooked = false

    private let expandAnimation = Animation.easeInOut(duration: 0.22)

    private var providers: [Provider] {
        sortNewest ? appModel.providers : appModel.providers.reversed()
    }

    private var bookedCount: Int {
        appModel.bookings.filter { $0.status == .booked }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(providers) { provider in
                        ProviderCard(provider: provider) {
                            bookingProvider = provider
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
                FilterSheet(criterion: criterion)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $bookingProvider) { provider in
                BookProviderSheet(provider: provider)
            }
            .onAppear {
                appModel.seedBookingsIfNeeded()
            }
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
                        FilterCriterionChip(criterion: criterion)
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
    case service
    case rating
    case price
    case availability

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location: "Location: in California; Bay Area"
        case .service: "Service"
        case .rating: "Rating"
        case .price: "Price"
        case .availability: "Availability"
        }
    }

    var shortTitle: String {
        switch self {
        case .location: "Location"
        case .service: "Service"
        case .rating: "Rating"
        case .price: "Price"
        case .availability: "Availability"
        }
    }

    var systemImage: String {
        switch self {
        case .location: "mappin"
        case .service: "archivebox"
        case .rating: "star"
        case .price: "dollarsign.circle"
        case .availability: "calendar"
        }
    }

    /// Only Location shows trailing chevron in the design.
    var showsChevron: Bool {
        self == .location
    }
}

private struct FilterCriterionChip: View {
    let criterion: HomeFilterCriterion

    private let fill = Color(red: 0.82, green: 0.84, blue: 0.91)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: criterion.systemImage)
                .font(.subheadline.weight(.semibold))

            Text(criterion.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            if criterion.showsChevron {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(Theme.darkText)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Provider card

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

    @State private var location = "California; Bay Area"
    @State private var service = "All"
    @State private var minRate = 20.0
    @State private var maxRate = 60.0
    @State private var minRateText = "20"
    @State private var maxRateText = "60"
    @State private var minRating = 4.0
    @State private var availability = "Any day"

    private let priceBounds: ClosedRange<Double> = 15...150
    private let priceStep: Double = 1

    var body: some View {
        NavigationStack {
            Form {
                switch criterion {
                case .location:
                    Section("Location") {
                        Picker("Area", selection: $location) {
                            Text("California; Bay Area").tag("California; Bay Area")
                            Text("California; Los Angeles").tag("California; Los Angeles")
                            Text("New York; NYC").tag("New York; NYC")
                            Text("Texas; Austin").tag("Texas; Austin")
                            Text("Remote only").tag("Remote only")
                        }
                    }
                case .service:
                    Section("Service") {
                        Picker("Service type", selection: $service) {
                            Text("All").tag("All")
                            Text("Personal Care").tag("Personal Care")
                            Text("Postpartum").tag("Postpartum")
                            Text("Companionship").tag("Companionship")
                            Text("Special Needs").tag("Special Needs")
                        }
                        .pickerStyle(.inline)
                    }
                case .rating:
                    Section("Minimum rating") {
                        Stepper(value: $minRating, in: 1...5, step: 0.5) {
                            Text(String(format: "%.1f+", minRating))
                        }
                    }
                case .price:
                    priceFilterSection
                case .availability:
                    Section("Availability") {
                        Picker("When", selection: $availability) {
                            Text("Any day").tag("Any day")
                            Text("Weekdays").tag("Weekdays")
                            Text("Weekends").tag("Weekends")
                            Text("Evenings").tag("Evenings")
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
                        if criterion == .price {
                            commitMinRateText()
                            commitMaxRateText()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                if criterion == .price {
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

    private var priceFilterSection: some View {
        Section {
            DualRangeSlider(
                minValue: $minRate,
                maxValue: $maxRate,
                bounds: priceBounds,
                step: priceStep
            )
            .padding(.vertical, 8)
            .onChange(of: minRate) { _, value in
                minRateText = String(Int(value.rounded()))
            }
            .onChange(of: maxRate) { _, value in
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

            Text("Showing $\(Int(minRate)) – $\(Int(maxRate))/hour")
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
        let parsed = Double(minRateText) ?? minRate
        let clamped = min(max(parsed, priceBounds.lowerBound), maxRate)
        minRate = clamped
        minRateText = String(Int(clamped.rounded()))
    }

    private func commitMaxRateText() {
        let parsed = Double(maxRateText) ?? maxRate
        let clamped = max(min(parsed, priceBounds.upperBound), minRate)
        maxRate = clamped
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
