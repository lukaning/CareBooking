import SwiftUI

@main
struct CareBookingApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .tint(Color("BrandOrange"))
        }
    }
}
