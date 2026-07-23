import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            PlaceholderTabView(title: "Messages", systemImage: "message")
                .tabItem {
                    Label("Messages", systemImage: "message")
                }

            PlaceholderTabView(title: "Notes", systemImage: "bookmark")
                .tabItem {
                    Label("Notes", systemImage: "bookmark")
                }

            PlaceholderTabView(title: "Payment", systemImage: "briefcase")
                .tabItem {
                    Label("Payment", systemImage: "briefcase")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(Theme.brandOrange)
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
