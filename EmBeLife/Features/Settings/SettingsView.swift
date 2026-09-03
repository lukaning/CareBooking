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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var path: [SettingsDestination] = []
    @State private var preferredLanguage = "English"
    @State private var showGiftFund = false

    private let languageOptions = AppLanguage.pickerNames
    private let rowColor = Color(red: 0.435, green: 0.463, blue: 0.494)
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
                    ForEach(filteredItems) { item in
                        settingsRow(item)
                    }

                    if showPreferences {
                        Divider()
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        preferencesSection
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search settings")
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isSearchPresented = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Search")
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
                case .giftFund:
                    // Fallback if path includes giftFund; prefer openSettingsItem fullScreenCover.
                    EmptyView()
                case .help:
                    SettingsDetailPlaceholder(destination: destination)
                }
            }
            .onAppear {
                preferredLanguage = appModel.preferredLanguage
            }
            .fullScreenCover(isPresented: $showGiftFund) {
                GiftGiverFlowHost()
            }
        }
        .tint(Theme.darkText)
    }

    private func openSettingsItem(_ item: SettingsDestination) {
        if item == .giftFund {
            // Present outside the Settings stack to avoid nested NavigationStack failure.
            showGiftFund = true
            return
        }
        path.append(item)
    }

    private func settingsRow(_ item: SettingsDestination) -> some View {
        Button {
            openSettingsItem(item)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.systemImage)
                    .font(.title3)
                    .foregroundStyle(rowColor)
                    .frame(width: 28, height: 28)

                Text(item.title.localizedKey)
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
                // Language — left label, right value (inline menu)
                Menu {
                    ForEach(languageOptions, id: \.self) { option in
                        Button {
                            preferredLanguage = option
                            appModel.preferredLanguage = option
                        } label: {
                            if preferredLanguage == option {
                                Label(option, systemImage: "checkmark")
                            } else {
                                Text(option)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "character.bubble")
                            .font(.title3)
                            .foregroundStyle(rowColor)
                            .frame(width: 28)

                        Text("Language Setting")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)

                        Spacer(minLength: 8)

                        Text(preferredLanguage)
                            .font(.body.weight(.medium))
                            .foregroundStyle(rowColor)
                            .lineLimit(1)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(rowColor)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()

                // Text size follows iPhone Settings → Display & Brightness / Accessibility.
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
                        Text(systemTextSizeLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(rowColor)
                    }

                    Text("Preview text looks like this.")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("EmBeLife uses the system text size from iPhone Settings.")
                        .font(.caption)
                        .foregroundStyle(rowColor)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open iPhone Settings")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.linkBlue)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .background(sectionFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var systemTextSizeLabel: String {
        switch dynamicTypeSize {
        case .xSmall, .small: "Small"
        case .medium, .large: "Default"
        case .xLarge, .xxLarge: "Large"
        case .xxxLarge: "Extra Large"
        default: "Accessibility"
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
