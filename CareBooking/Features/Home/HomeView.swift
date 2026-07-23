import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showFilters = false
    @State private var bookingProvider: Provider?
    @State private var sortNewest = true

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
                        // Settings entry point from design hamburger
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
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

                    Spacer()

                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundStyle(Theme.darkText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $bookingProvider) { provider in
                BookProviderSheet(provider: provider)
            }
        }
    }
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

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var maxRate = 50.0
    @State private var minRating = 4.0
    @State private var specialty = "All"

    var body: some View {
        NavigationStack {
            Form {
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

                Section("Minimum rating") {
                    Stepper(value: $minRating, in: 1...5, step: 0.5) {
                        Text(String(format: "%.1f+", minRating))
                    }
                }

                Section("Specialty") {
                    Picker("Specialty", selection: $specialty) {
                        Text("All").tag("All")
                        Text("Personal Care").tag("Personal Care")
                        Text("Postpartum").tag("Postpartum")
                        Text("Companionship").tag("Companionship")
                    }
                }
            }
            .navigationTitle("Filters")
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
