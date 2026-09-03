import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            switch appModel.flow {
            case .auth:
                AuthFlowView()
            case .onboarding:
                OnboardingFlowView()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appModel.flow)
        .environment(\.locale, appModel.appLocale)
        .environment(\.layoutDirection, appModel.appLanguage.layoutDirection)
    }
}

#Preview {
    RootView()
        .environment(AppModel())
}
