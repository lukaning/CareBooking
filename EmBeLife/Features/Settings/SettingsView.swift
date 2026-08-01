import SwiftUI

enum SettingsDestination: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case userManagement
    case account
    case bookings
    case giftFund
    case language
    case textSize
    case help

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .userManagement: "User management"
        case .account: "Account"
        case .bookings: "Bookings"
        case .giftFund: "Gift Fund"
        case .language: "Language Setting"
        case .textSize: "Text Size"
        case .help: "Help & getting started"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .userManagement: "person.crop.rectangle.stack"
        case .account: "person.crop.circle"
        case .bookings: "diamond"
        case .giftFund: "wallet.pass"
        case .language: "character.bubble"
        case .textSize: "textformat.size"
        case .help: "questionmark.circle"
        }
    }

    var badgeCount: Int? {
        switch self {
        case .help: 1
        default: nil
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var path: [SettingsDestination] = []

    private let rowColor = Color(red: 0.435, green: 0.463, blue: 0.494) // #6F767E
    private let searchPlaceholder = Color(red: 0.396, green: 0.471, blue: 0.557) // #65788E
    private let searchFill = Color(red: 0.941, green: 0.957, blue: 0.976) // #F0F4F9
    private let badgeFill = Color(red: 0.792, green: 0.741, blue: 1.0) // #CABDFF
    private let badgeText = Color(red: 0.102, green: 0.114, blue: 0.122) // #1A1D1F

    private var filteredItems: [SettingsDestination] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SettingsDestination.allCases }
        return SettingsDestination.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    searchField
                        .padding(.bottom, 8)

                    ForEach(filteredItems) { item in
                        settingsRow(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Theme.darkText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(.account)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                    }
                    .accessibilityLabel("Edit profile")
                }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .userManagement:
                    UserManagementView()
                default:
                    SettingsDetailPlaceholder(destination: destination)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(searchPlaceholder)

            TextField("Search..", text: $searchText)
                .font(.body.weight(.medium))
                .foregroundStyle(Theme.darkText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(searchFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func settingsRow(_ item: SettingsDestination) -> some View {
        Button {
            path.append(item)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.systemImage)
                    .font(.title3)
                    .foregroundStyle(rowColor)
                    .frame(width: 28, height: 28)

                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(rowColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let badge = item.badgeCount {
                    Text("\(badge)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(badgeText)
                        .frame(width: 28, height: 28)
                        .background(badgeFill)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(rowColor)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsDetailPlaceholder: View {
    let destination: SettingsDestination

    var body: some View {
        ContentUnavailableView(
            destination.title,
            systemImage: destination.systemImage,
            description: Text("Coming soon in a later scope.")
        )
        .navigationTitle(destination.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
