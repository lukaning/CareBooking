import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var appModel
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHero()

            Group {
                switch step {
                case 0:
                    RoleLanguageStep(onContinue: { step = 1 })
                case 1:
                    ServiceNeedsStep(onContinue: { step = 2 })
                default:
                    LocationStep(onContinue: { appModel.finishOnboarding() })
                }
            }
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: step)
    }
}

struct OnboardingHero: View {
    var body: some View {
        HeroHeaderImage()
            .overlay(alignment: .top) {
                Theme.brandOrange
                    .frame(height: 0)
                    .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
            }
            .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
    }
}

struct RoleLanguageStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    private let languages = ["English", "Spanish", "Chinese", "French"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Do you need help or can you provide services?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Text("Select Your Preferred Language")
                                .font(.headline)
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Theme.grayscale60)
                        }

                        Menu {
                            ForEach(languages, id: \.self) { language in
                                Button(language) {
                                    appModel.preferredLanguage = language
                                }
                            }
                        } label: {
                            HStack {
                                Text(appModel.preferredLanguage)
                                    .font(.headline)
                                    .foregroundStyle(Theme.darkText)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(Theme.grayscale60)
                            }
                            .padding(16)
                            .background(Color(red: 0.988, green: 0.988, blue: 0.988))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.cardBorder, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    roleCard(
                        role: .client,
                        title: "I'm looking for help or support",
                        subtitle: "Those are usually the Individuals who need help",
                        image: "roleClient"
                    )

                    roleCard(
                        role: .provider,
                        title: "I'm a Provider",
                        subtitle: "Those are usually professionals",
                        image: "roleProvider"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            bottomBar(title: "Get Started", enabled: appModel.selectedRole != nil, action: onContinue)
        }
    }

    private func roleCard(role: UserRole, title: String, subtitle: String, image: String) -> some View {
        let selected = appModel.selectedRole == role
        return Button {
            appModel.selectedRole = role
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.537, green: 0.537, blue: 0.537))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.988, green: 0.988, blue: 0.988))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Theme.brandOrange : Theme.cardBorder, lineWidth: selected ? 2.5 : 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ServiceNeedsStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What kind of help or support do you need?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    ForEach(ServiceCategory.all) { service in
                        serviceRow(service)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            bottomBar(title: "Next", enabled: !appModel.selectedServiceIDs.isEmpty, action: onContinue)
        }
    }

    private func serviceRow(_ service: ServiceCategory) -> some View {
        let selected = appModel.selectedServiceIDs.contains(service.id)
        return Button {
            if selected {
                appModel.selectedServiceIDs.remove(service.id)
            } else {
                appModel.selectedServiceIDs.insert(service.id)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? Theme.brandOrange : Theme.grayscale60)

                Image(service.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)

                Text(service.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

struct LocationStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Where do you need help?")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .padding(.top, 28)

                    locationRow(
                        choice: .current,
                        title: "Use current location",
                        titleColor: Color(red: 0.114, green: 0.631, blue: 0.949)
                    )

                    locationRow(
                        choice: .custom,
                        title: "Customize location",
                        titleColor: Color.black.opacity(0.75)
                    )

                    if appModel.locationChoice == .custom {
                        TextField("Enter city or address", text: Binding(
                            get: { appModel.customLocation },
                            set: { appModel.customLocation = $0 }
                        ))
                        .padding(14)
                        .background(Theme.inputFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            bottomBar(
                title: "Next",
                enabled: appModel.locationChoice != nil && (appModel.locationChoice != .custom || !appModel.customLocation.isEmpty),
                action: onContinue
            )
        }
    }

    private func locationRow(choice: LocationChoice, title: String, titleColor: Color) -> some View {
        let selected = appModel.locationChoice == choice
        return Button {
            appModel.locationChoice = choice
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? Theme.brandOrange : Theme.grayscale60)

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.brandOrange)
                        .frame(width: 40, height: 40)
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(titleColor)

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private func bottomBar(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        Divider().opacity(0.01)
        Button(title, action: action)
            .buttonStyle(PrimaryBlackButtonStyle())
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.45)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.08), radius: 24, y: -8)
            )
    }
}
