import SwiftUI

enum SettingsDestination: String, CaseIterable, Identifiable, Hashable {
    case profile
    case dashboard
    case userManagement
    case passwordSecurity
    case activities
    case giftFund
    case help

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile: "Profile"
        case .dashboard: "Dashboard"
        case .userManagement: "User management"
        case .passwordSecurity: "Password & Security"
        case .activities: "Activities"
        case .giftFund: "Gift Fund"
        case .help: "Help & getting started"
        }
    }

    var systemImage: String {
        switch self {
        case .profile: "person.crop.circle"
        case .dashboard: "square.grid.2x2"
        case .userManagement: "person.crop.rectangle.stack"
        case .passwordSecurity: "lock.shield"
        case .activities: "list.bullet.rectangle"
        case .giftFund: "wallet.pass"
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
    @Environment(AppModel.self) private var appModel

    @State private var searchText = ""
    @State private var path: [SettingsDestination] = []
    @State private var preferredLanguage = "English"
    @State private var textSizeValue: Double = 1.0

    private let languageOptions = ["English", "Spanish", "Mandarin", "Cantonese", "French", "ASL"]
    private let rowColor = Color(red: 0.435, green: 0.463, blue: 0.494)
    private let searchPlaceholder = Color(red: 0.396, green: 0.471, blue: 0.557)
    private let searchFill = Color(red: 0.941, green: 0.957, blue: 0.976)
    private let badgeFill = Color(red: 0.792, green: 0.741, blue: 1.0)
    private let badgeText = Color(red: 0.102, green: 0.114, blue: 0.122)
    private let sectionFill = Color(red: 0.97, green: 0.975, blue: 0.985)

    private var filteredItems: [SettingsDestination] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SettingsDestination.allCases }
        return SettingsDestination.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    private var showPreferences: Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return "Language Setting".localizedCaseInsensitiveContains(query)
            || "Language".localizedCaseInsensitiveContains(query)
            || "Text Size".localizedCaseInsensitiveContains(query)
            || "Text".localizedCaseInsensitiveContains(query)
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

                    if showPreferences {
                        preferencesSection
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .profile:
                    ProfileView(embedsNavigation: false)
                case .dashboard:
                    DashboardView()
                case .userManagement:
                    UserManagementView()
                case .passwordSecurity:
                    PasswordSecurityView()
                case .activities:
                    ActivitiesView()
                case .giftFund, .help:
                    SettingsDetailPlaceholder(destination: destination)
                }
            }
            .onAppear {
                preferredLanguage = appModel.preferredLanguage
            }
        }
        .tint(Theme.darkText)
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

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Display & Language")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(rowColor)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 18) {
                // Language — inline control, no drill-down
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "character.bubble")
                            .font(.title3)
                            .foregroundStyle(rowColor)
                            .frame(width: 28)
                        Text("Language Setting")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                    }

                    Picker("Language", selection: $preferredLanguage) {
                        ForEach(languageOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.brandOrange)
                    .onChange(of: preferredLanguage) { _, newValue in
                        appModel.preferredLanguage = newValue
                    }
                }

                Divider()

                // Text size — inline slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "textformat.size")
                            .font(.title3)
                            .foregroundStyle(rowColor)
                            .frame(width: 28)
                        Text("Text Size")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                        Spacer()
                        Text(textSizeLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(rowColor)
                    }

                    HStack(spacing: 12) {
                        Text("A")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(rowColor)
                        Slider(value: $textSizeValue, in: 0.85...1.3, step: 0.05)
                            .tint(Theme.brandOrange)
                        Text("A")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(rowColor)
                    }

                    Text("Preview text looks like this.")
                        .font(.system(size: 16 * textSizeValue, weight: .medium))
                        .foregroundStyle(Theme.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .background(sectionFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var textSizeLabel: String {
        switch textSizeValue {
        case ..<0.95: return "Small"
        case ..<1.1: return "Default"
        case ..<1.2: return "Large"
        default: return "Extra Large"
        }
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
        .environment(AppModel())
}
