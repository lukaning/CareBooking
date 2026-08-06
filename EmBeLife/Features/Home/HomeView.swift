import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var filtersExpanded = false
    @State private var activeFilter: HomeFilterCriterion?
    @State private var showSettings = false
    @State private var bookingProvider: Provider?
    @State private var sortNewest = true

    private let expandAnimation = Animation.easeInOut(duration: 0.22)

    private var providers: [Provider] {
        sortNewest ? appModel.providers : appModel.providers.reversed()
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
                }
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
    @State private var maxRate = 50.0
    @State private var minRating = 4.0
    @State private var availability = "Any day"

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
                    Section("Rate") {
                        Slider(value: $maxRate, in: 15...100, step: 5) {
                            Text("Max rate")
                        } minimumValueLabel: {
                            Text("$15")
                        } maximumValueLabel: {
                            Text("$100")
                        }
                        Text("Up to $\(Int(maxRate))/hour")
                            .foregroundStyle(.secondary)
                    }
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
                    Button("Apply") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
