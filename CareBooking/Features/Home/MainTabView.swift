import SwiftUI
import UIKit

enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case home
    case messages
    case notes
    case notification
    case payment
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .messages: "Messages"
        case .notes: "Notes"
        case .notification: "Notification"
        case .payment: "Payment"
        case .profile: "Profile"
        }
    }

    /// Outline glyph for inactive state
    var outlineSymbol: String {
        switch self {
        case .home: "house"
        case .messages: "message"
        case .notes: "bookmark"
        case .notification: "bell"
        case .payment: "briefcase"
        case .profile: "person"
        }
    }

    /// Filled glyph for active state (matches Figma selected tabs)
    var fillSymbol: String {
        switch self {
        case .home: "house.fill"
        case .messages: "message.fill"
        case .notes: "bookmark.fill"
        case .notification: "bell.fill"
        case .payment: "briefcase.fill"
        case .profile: "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    tabLabel(.home)
                }
                .tag(AppTab.home)

            PlaceholderTabView(title: AppTab.messages.title, systemImage: AppTab.messages.fillSymbol)
                .tabItem {
                    tabLabel(.messages)
                }
                .tag(AppTab.messages)

            PlaceholderTabView(title: AppTab.notes.title, systemImage: AppTab.notes.fillSymbol)
                .tabItem {
                    tabLabel(.notes)
                }
                .tag(AppTab.notes)

            PlaceholderTabView(title: AppTab.notification.title, systemImage: AppTab.notification.fillSymbol)
                .tabItem {
                    tabLabel(.notification)
                }
                .tag(AppTab.notification)

            PlaceholderTabView(title: AppTab.payment.title, systemImage: AppTab.payment.fillSymbol)
                .tabItem {
                    tabLabel(.payment)
                }
                .tag(AppTab.payment)

            ProfileView()
                .tabItem {
                    tabLabel(.profile)
                }
                .tag(AppTab.profile)
        }
        .tint(Theme.brandOrange)
        .onAppear(perform: configureTabBarAppearance)
    }

    @ViewBuilder
    private func tabLabel(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        Label(
            tab.title,
            systemImage: isSelected ? tab.fillSymbol : tab.outlineSymbol
        )
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        let inactive = UIColor(red: 0.612, green: 0.639, blue: 0.686, alpha: 1) // #9CA3AF
        let active = UIColor(red: 0.945, green: 0.349, blue: 0.145, alpha: 1) // BrandOrange

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = inactive
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: inactive,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        itemAppearance.selected.iconColor = active
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: active,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = inactive
        UITabBar.appearance().tintColor = active
    }
}

struct PlaceholderTabView: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Coming soon in a later scope."))
                .navigationTitle(title)
        }
    }
}
