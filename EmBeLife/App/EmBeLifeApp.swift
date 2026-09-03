import SwiftUI

@main
struct EmBeLifeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .environment(\.locale, appModel.appLocale)
                .environment(\.layoutDirection, appModel.appLanguage.layoutDirection)
                .tint(Color("BrandOrange"))
                // Allow the full Dynamic Type range from iPhone Settings.
                .dynamicTypeSize(.xSmall ... .accessibility5)
                .onOpenURL { url in
                    SocialAuthService.shared.handleOpenURL(url)
                }
        }
    }
}
