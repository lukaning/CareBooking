import SwiftUI

@main
struct EmBeLifeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .tint(Color("BrandOrange"))
                // Allow the full Dynamic Type range from iPhone Settings.
                .dynamicTypeSize(.xSmall ... .accessibility5)
        }
    }
}
