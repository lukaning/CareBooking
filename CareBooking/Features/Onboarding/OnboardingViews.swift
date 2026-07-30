import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var appModel
    @State private var step = 0

    var body: some View {
        Group {
            switch step {
            case 0:
                WelcomeStep(
                    onContinue: { step = 1 },
                    onSkip: { appModel.finishOnboarding() }
                )
            case 1:
                OnboardingStepContainer {
                    RoleLanguageStep(onContinue: { step = 2 })
                }
            case 2:
                OnboardingStepContainer {
                    ServiceNeedsStep(onContinue: { step = 3 })
                }
            default:
                OnboardingStepContainer {
                    LocationStep(onContinue: { appModel.finishOnboarding() })
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }
}

private struct OnboardingStepContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHero()
            content
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingHero: View {
    var body: some View {
        HeroHeaderImage()
            .background(Theme.brandOrange.ignoresSafeArea(edges: .top))
    }
}

// MARK: - Welcome

struct WelcomeStep: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image("onboardingHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 340)
                    .clipped()

                Button("Skip", action: onSkip)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.top, 8)
                    .padding(.trailing, 12)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, 👋")
                        .font(.system(size: 34, weight: .bold))
                    Text("Welcome to")
                        .font(.system(size: 34, weight: .bold))
                }
                .foregroundStyle(Theme.darkText)

                EmBeLifeLogo()

                Text("Find trustworthy help and support...")
                    .font(.body)
                    .foregroundStyle(Theme.grayscale70)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer(minLength: 0)

            Button("Next", action: onContinue)
                .buttonStyle(PrimaryOrangeButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Color(.systemBackground)
                        .shadow(color: .black.opacity(0.08), radius: 24, y: -8)
                )
        }
        .background(Color(red: 0.965, green: 0.973, blue: 0.996))
    }
}

// MARK: - Role & Language

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
                                    .stroke(Color(red: 0.937, green: 0.937, blue: 0.937), lineWidth: 2)
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

            onboardingBottomBar(title: "Get Started", enabled: appModel.selectedRole != nil, action: onContinue)
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
                    .stroke(selected ? Theme.brandOrange : Color(red: 0.925, green: 0.925, blue: 0.953), lineWidth: selected ? 2.5 : 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Service Needs

struct ServiceNeedsStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    @State private var expandedCategoryID: String?

    private var canContinue: Bool {
        guard let categoryID = expandedCategoryID else { return false }
        let subs = appModel.selectedSubServiceIDs[categoryID] ?? []
        return !subs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What kind of help or support do you need?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    ForEach(ServiceCategory.all) { service in
                        serviceCategoryCard(service)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            onboardingBottomBar(title: "Next", enabled: canContinue, action: onContinue)
        }
    }

    private func serviceCategoryCard(_ service: ServiceCategory) -> some View {
        let isSelected = expandedCategoryID == service.id
        let subOptions = OnboardingServiceCatalog.subOptions(for: service.id)
        let selectedSubs = appModel.selectedSubServiceIDs[service.id] ?? []

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    if expandedCategoryID == service.id {
                        expandedCategoryID = nil
                    } else {
                        expandedCategoryID = service.id
                        appModel.selectedServiceIDs = [service.id]
                        if appModel.selectedSubServiceIDs[service.id] == nil {
                            appModel.selectedSubServiceIDs[service.id] = []
                        }
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(isSelected ? "radioFilled" : "radioEmpty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)

                    Image(service.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)

                    Text(service.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isSelected ? Theme.brandOrange : .primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(red: 0.8, green: 0.73, blue: 0.73).opacity(0.25), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            if isSelected {
                FlowLayout(spacing: 10) {
                    ForEach(subOptions) { option in
                        subServiceChip(option, categoryID: service.id, isSelected: selectedSubs.contains(option.id))
                    }
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func subServiceChip(_ option: ServiceSubOption, categoryID: String, isSelected: Bool) -> some View {
        Button {
            var set = appModel.selectedSubServiceIDs[categoryID] ?? []
            if isSelected {
                set.remove(option.id)
            } else {
                set.insert(option.id)
            }
            appModel.selectedSubServiceIDs[categoryID] = set
        } label: {
            HStack(spacing: 8) {
                Text(option.title)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : Theme.darkText)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : Theme.grayscale60)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.brandOrange : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(red: 0.933, green: 0.933, blue: 0.933), lineWidth: isSelected ? 0 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location

struct LocationStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    @State private var showLocationPermission = false

    private var canContinue: Bool {
        switch appModel.locationChoice {
        case .current:
            return true
        case .custom:
            return appModel.customLocationConfirmed
        case .none:
            return false
        }
    }

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

                    VStack(alignment: .leading, spacing: 14) {
                        locationRow(
                            choice: .custom,
                            title: "Customize location",
                            titleColor: Color.black.opacity(0.75)
                        )

                        if appModel.locationChoice == .custom {
                            customizeLocationForm
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            onboardingBottomBar(title: "Next", enabled: canContinue, action: onContinue)
        }
        .alert("Allow CareBooking to use your location?", isPresented: $showLocationPermission) {
            Button("Allow While Using the App") {
                appModel.locationChoice = .current
            }
            Button("Allow Once") {
                appModel.locationChoice = .current
            }
            Button("Don't Allow", role: .cancel) {}
        } message: {
            Text("Your location is used to find nearby care providers and will not be shared with third parties.")
        }
    }

    private var customizeLocationForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Address", text: Binding(
                get: { appModel.customAddress },
                set: {
                    appModel.customAddress = $0
                    appModel.customLocationConfirmed = false
                }
            ))
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            TextField("Zipcode", text: Binding(
                get: { appModel.customZipcode },
                set: {
                    appModel.customZipcode = $0
                    appModel.customLocationConfirmed = false
                }
            ))
            .keyboardType(.numberPad)
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Your address is used to confirm your account and will not to be shared with any third parties")
                .font(.caption)
                .foregroundStyle(Theme.grayscale70)
                .fixedSize(horizontal: false, vertical: true)

            mapPreview

            VStack(alignment: .leading, spacing: 10) {
                Text("Select Distance")
                    .font(.subheadline.weight(.bold))

                Slider(
                    value: Binding(
                        get: { appModel.searchRadiusMiles },
                        set: {
                            appModel.searchRadiusMiles = $0
                            appModel.customLocationConfirmed = false
                        }
                    ),
                    in: 1...250,
                    step: 1
                )
                .tint(Theme.brandOrange)

                HStack {
                    Text("1 mile")
                    Spacer()
                    Text("250 miles")
                }
                .font(.caption.weight(.semibold))
            }

            Button("Confirm") {
                appModel.customLocation = [appModel.customAddress, appModel.customZipcode]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                appModel.customLocationConfirmed = !appModel.customAddress.isEmpty
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.brandOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(appModel.customAddress.isEmpty)
            .opacity(appModel.customAddress.isEmpty ? 0.5 : 1)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color(red: 0.8, green: 0.73, blue: 0.73).opacity(0.25), radius: 8, y: 4)
    }

    private var mapPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.91, green: 0.93, blue: 0.95))
                .frame(height: 180)

            Circle()
                .fill(Theme.brandOrange.opacity(0.15))
                .frame(width: 120, height: 120)

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.brandOrange)
        }
    }

    private func locationRow(choice: LocationChoice, title: String, titleColor: Color) -> some View {
        let selected = appModel.locationChoice == choice
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                if choice == .current {
                    showLocationPermission = true
                } else {
                    appModel.locationChoice = choice
                    appModel.customLocationConfirmed = false
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(selected ? "radioFilled" : "radioEmpty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.brandOrange)
                        .frame(width: 40, height: 40)
                    Image("pinIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
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

// MARK: - Shared

private func onboardingBottomBar(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
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

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
