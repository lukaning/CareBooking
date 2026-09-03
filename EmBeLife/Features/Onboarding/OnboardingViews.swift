import CoreLocation
import MapKit
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
                    onSignUpIn: { appModel.showAuth() }
                )
            case 1:
                OnboardingStepContainer(onBack: { step = 0 }, onExit: exitOnboarding) {
                    RoleLanguageStep(onContinue: { step = 2 })
                }
            case 2:
                OnboardingStepContainer(onBack: { step = 1 }, onExit: exitOnboarding) {
                    ServiceNeedsStep(onContinue: { step = 3 })
                }
            default:
                OnboardingStepContainer(onBack: { step = 2 }, onExit: exitOnboarding) {
                    LocationStep(onContinue: { appModel.finishOnboarding() })
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
        .onAppear {
            if appModel.skipWelcomeStep {
                appModel.skipWelcomeStep = false
                if step == 0 {
                    step = 1
                }
            }
        }
    }

    private func exitOnboarding() {
        if appModel.isSignedIn {
            appModel.finishOnboarding()
        } else {
            appModel.showAuth()
        }
    }
}

private struct OnboardingStepContainer<Content: View>: View {
    var onBack: (() -> Void)?
    var onExit: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                OnboardingHero()
                if onBack != nil || onExit != nil {
                    HStack {
                        AuthBackButton(action: onBack)
                        Spacer()
                        if let onExit {
                            Button(action: onExit) {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Exit")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
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
    var onSignUpIn: () -> Void

    private let pageBG = Color(red: 0.99, green: 0.99, blue: 0.995)
    private let tagline = Color(red: 0.48, green: 0.50, blue: 0.54)

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    Image("onboardingHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .frame(height: welcomeHeroHeight)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)

                Button(action: onSignUpIn) {
                    Text("Sign up/in")
                        .font(.scaledSystem(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.28))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.trailing, 16)
                .accessibilityLabel("Sign up or sign in")
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Hi, 👋")
                    .font(.scaledSystem(size: 56, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(.top, 10)

                Text("Welcome to")
                    .font(.scaledSystem(size: 56, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(.top, 2)

                Image("embelifeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 52)
                    .frame(maxWidth: 200, alignment: .leading)
                    .padding(.top, 18)
                    .accessibilityLabel("EmBeLife")

                Text("Find trustworthy help and rehabilitative services")
                    .font(.scaledSystem(size: 15, weight: .regular))
                    .foregroundStyle(tagline)
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            Button("Next", action: onContinue)
                .buttonStyle(PrimaryOrangeButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .background(pageBG.ignoresSafeArea())
    }

    private var welcomeHeroHeight: CGFloat {
        // Larger photo band; greeting sits with a tight gap below the white edge.
        min(380, max(280, UIScreen.main.bounds.height * 0.44))
    }
}

// MARK: - Role & Language

struct RoleLanguageStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    @State private var isLanguageMenuOpen = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Do you need help or can you provide services?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.darkText)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Select Your Preferred Language")
                            .font(.headline)
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.grayscale60)
                    }

                    LanguageDropdown(
                        selection: Binding(
                            get: { appModel.preferredLanguage },
                            set: { appModel.preferredLanguage = $0 }
                        ),
                        isOpen: $isLanguageMenuOpen
                    ) {
                        VStack(spacing: 20) {
                            roleCard(
                                role: .client,
                                title: LocalizedMarkdownText(key: "I'm **looking** for help or rehabilitative services"),
                                subtitle: "Those are usually the Individuals who need help",
                                image: "roleClient",
                                selectedImage: "roleClientSelected"
                            )

                            roleCard(
                                role: .provider,
                                title: LocalizedMarkdownText(key: "I **provide** help or rehabilitative services"),
                                subtitle: "Those are usually professionals",
                                image: "roleProvider",
                                selectedImage: "roleProviderSelected"
                            )

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            onboardingBottomBar(title: "Get Started", enabled: appModel.selectedRole != nil, action: onContinue)
        }
    }

    private func roleCard(
        role: UserRole,
        title: LocalizedMarkdownText,
        subtitle: String,
        image: String,
        selectedImage: String
    ) -> some View {
        let selected = appModel.selectedRole == role
        let unselectedBorder = Color(red: 0.886, green: 0.886, blue: 0.902) // #E2E2E6

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isLanguageMenuOpen = false
                appModel.selectedRole = role
            }
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Image(selected ? selectedImage : image)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    title
                        .font(.headline.weight(.regular))
                        .foregroundStyle(Theme.darkText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle.localizedKey)
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.537, green: 0.537, blue: 0.537))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Theme.brandOrange : unselectedBorder, lineWidth: selected ? 3 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }
}

private struct LanguageDropdown<Backdrop: View>: View {
    @Binding var selection: String
    @Binding var isOpen: Bool
    @ViewBuilder var backdrop: Backdrop

    private let languages = AppLanguage.pickerNames

    private let fill = Color(red: 0.988, green: 0.988, blue: 0.988)
    private let border = Color(red: 0.937, green: 0.937, blue: 0.937)
    private let selectedFill = Color(red: 0.937, green: 0.937, blue: 0.937)
    private let muted = Color(red: 0.537, green: 0.537, blue: 0.537)

    var body: some View {
        VStack(spacing: 20) {
            header
            backdrop
        }
        .overlay(alignment: .top) {
            if isOpen {
                VStack(spacing: 0) {
                    header
                    Rectangle()
                        .fill(border)
                        .frame(height: 1)
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(languages, id: \.self) { language in
                                languageRow(language)
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(border, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isOpen)
    }

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isOpen.toggle()
            }
        } label: {
            HStack {
                Text(selection)
                    .font(.headline)
                    .foregroundStyle(Theme.darkText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.grayscale60)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(border, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Preferred language")
        .accessibilityValue(selection)
        .accessibilityHint(isOpen ? "Collapses the language list" : "Expands the language list")
    }

    private func languageRow(_ language: String) -> some View {
        let selected = language == selection
        return Button {
            selection = language
            withAnimation(.easeInOut(duration: 0.18)) {
                isOpen = false
            }
        } label: {
            Text(language)
                .font(.body.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? Theme.darkText : muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(selected ? selectedFill : Color.white)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Service Needs

struct ServiceNeedsStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    @State private var selectedCategoryID: String?

    private let chipAnimation = Animation.spring(response: 0.28, dampingFraction: 0.72)
    private let expandAnimation = Animation.easeInOut(duration: 0.2)

    private var canContinue: Bool {
        guard let categoryID = selectedCategoryID else { return false }
        let selectedLeaves = appModel.selectedSubServiceIDs[categoryID] ?? []
        guard !selectedLeaves.isEmpty else { return false }

        // "Other (describe)" requires text.
        return selectedLeaves.allSatisfy { leafID in
            guard let option = OnboardingServiceCatalog.option(id: leafID, in: categoryID) else {
                return true
            }
            guard option.requiresDescription else { return true }
            let note = appModel.serviceOptionNotes[leafID]?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !note.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What kind of help or rehabilitative services do you need?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    ForEach(ServiceCategory.all) { service in
                        serviceCategoryRow(service)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)

            onboardingBottomBar(title: "Next", enabled: canContinue, action: onContinue)
        }
    }

    private func serviceCategoryRow(_ service: ServiceCategory) -> some View {
        let isSelected = selectedCategoryID == service.id
        let groups = OnboardingServiceCatalog.optionGroups(for: service.id)
        let isNested = !groups.isEmpty

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                selectCategory(service.id)
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    OnboardingRadioControl(isSelected: isSelected)

                    serviceCategoryIcon(service, isSelected: isSelected)

                    Text(service.title.localizedKey)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isSelected ? Theme.brandOrange : Theme.darkText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(ServiceRowButtonStyle())

            if isSelected {
                Group {
                    if isNested {
                        nestedOptionsContent(categoryID: service.id, groups: groups)
                    } else {
                        flatOptionsContent(categoryID: service.id)
                    }
                }
                .padding(.leading, 40)
                .padding(.top, 4)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .animation(expandAnimation, value: isSelected)
        .animation(expandAnimation, value: appModel.selectedServiceGroupIDs[service.id] ?? [])
    }

    private func flatOptionsContent(categoryID: String) -> some View {
        let subOptions = OnboardingServiceCatalog.subOptions(for: categoryID)
        let selectedSubs = appModel.selectedSubServiceIDs[categoryID] ?? []

        return FlowLayout(spacing: 10) {
            ForEach(subOptions) { option in
                subServiceChip(
                    option,
                    categoryID: categoryID,
                    isSelected: selectedSubs.contains(option.id)
                )
            }
        }
    }

    private func nestedOptionsContent(categoryID: String, groups: [ServiceOptionGroup]) -> some View {
        let selectedGroups = appModel.selectedServiceGroupIDs[categoryID] ?? []
        let selectedLeaves = appModel.selectedSubServiceIDs[categoryID] ?? []

        // Level 2 list first; Level 3 only expands under each selected Level 2.
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(groups) { group in
                let groupSelected = selectedGroups.contains(group.id)

                VStack(alignment: .leading, spacing: 10) {
                    groupChip(
                        group,
                        categoryID: categoryID,
                        isSelected: groupSelected
                    )

                    if groupSelected {
                        VStack(alignment: .leading, spacing: 10) {
                            FlowLayout(spacing: 10) {
                                ForEach(group.children) { option in
                                    subServiceChip(
                                        option,
                                        categoryID: categoryID,
                                        isSelected: selectedLeaves.contains(option.id)
                                    )
                                }
                            }

                            ForEach(group.children.filter {
                                selectedLeaves.contains($0.id) && ($0.allowsNotes || $0.requiresDescription)
                            }) { option in
                                notesField(for: option)
                            }
                        }
                        .padding(.leading, 8)
                        .transition(.opacity)
                    }
                }
                .animation(expandAnimation, value: groupSelected)
            }
        }
    }

    private func notesField(for option: ServiceSubOption) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text(option.requiresDescription ? "Describe: " : "Notes: ")
                + Text(option.title.localizedKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.grayscale70)

            TextField(
                option.requiresDescription ? "Describe your needs…" : "Add specific instructions or notes…",
                text: Binding(
                    get: { appModel.serviceOptionNotes[option.id] ?? "" },
                    set: { appModel.serviceOptionNotes[option.id] = $0 }
                ),
                axis: .vertical
            )
            .lineLimit(2...4)
            .font(.subheadline)
            .padding(12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    @ViewBuilder
    private func serviceCategoryIcon(_ service: ServiceCategory, isSelected: Bool) -> some View {
        if let selectedImageName = service.selectedImageName {
            Image(isSelected ? selectedImageName : service.imageName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 48, height: 48)
        } else {
            Image(service.imageName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(isSelected ? Theme.brandOrange : Theme.darkText)
        }
    }

    private func selectCategory(_ id: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        withAnimation(expandAnimation) {
            if selectedCategoryID == id {
                selectedCategoryID = nil
                appModel.selectedServiceIDs = []
                appModel.clearServiceSelections(for: id)
                return
            }

            if let previous = selectedCategoryID {
                appModel.clearServiceSelections(for: previous)
            }
            selectedCategoryID = id
            appModel.selectedServiceIDs = [id]
            if appModel.selectedSubServiceIDs[id] == nil {
                appModel.selectedSubServiceIDs[id] = []
            }
            if appModel.selectedServiceGroupIDs[id] == nil {
                appModel.selectedServiceGroupIDs[id] = []
            }
        }
    }

    private func groupChip(_ group: ServiceOptionGroup, categoryID: String, isSelected: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(chipAnimation) {
                var groups = appModel.selectedServiceGroupIDs[categoryID] ?? []
                var leaves = appModel.selectedSubServiceIDs[categoryID] ?? []
                if isSelected {
                    groups.remove(group.id)
                    for child in group.children {
                        leaves.remove(child.id)
                        appModel.serviceOptionNotes.removeValue(forKey: child.id)
                    }
                } else {
                    groups.insert(group.id)
                }
                appModel.selectedServiceGroupIDs[categoryID] = groups
                appModel.selectedSubServiceIDs[categoryID] = leaves
            }
        } label: {
            HStack(spacing: 8) {
                Text(group.title.localizedKey)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Theme.darkText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .white.opacity(0.95) : Theme.grayscale60)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.brandOrange : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Theme.brandOrange : Color(red: 0.933, green: 0.933, blue: 0.933),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(
                color: isSelected ? Theme.brandOrange.opacity(0.22) : .clear,
                radius: isSelected ? 6 : 0,
                y: isSelected ? 2 : 0
            )
        }
        .buttonStyle(ChipPressButtonStyle())
    }

    private func subServiceChip(_ option: ServiceSubOption, categoryID: String, isSelected: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(chipAnimation) {
                var set = appModel.selectedSubServiceIDs[categoryID] ?? []
                if isSelected {
                    set.remove(option.id)
                    appModel.serviceOptionNotes.removeValue(forKey: option.id)
                } else {
                    set.insert(option.id)
                }
                appModel.selectedSubServiceIDs[categoryID] = set
            }
        } label: {
            HStack(spacing: 8) {
                Text(option.title.localizedKey)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : Theme.darkText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.scaledSystem(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isSelected ? Theme.brandOrange : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Theme.brandOrange : Color(red: 0.933, green: 0.933, blue: 0.933),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(
                color: isSelected ? Theme.brandOrange.opacity(0.22) : .clear,
                radius: isSelected ? 6 : 0,
                y: isSelected ? 2 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(ChipPressButtonStyle())
    }
}

private struct ServiceRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct ChipPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Location

struct LocationStep: View {
    @Environment(AppModel.self) private var appModel
    var onContinue: () -> Void

    private enum CustomField: Hashable {
        case address
        case zipcode
    }

    @State private var locationManager = LocationManager()
    @State private var mapCoordinate = LocationManager.sampleCoordinate
    @FocusState private var customFieldFocus: CustomField?

    private let titleBlue = Color(red: 0.114, green: 0.631, blue: 0.949)
    private let expandAnimation = Animation.easeInOut(duration: 0.2)
    private let customConfirmAnchor = "customConfirm"

    private var canContinue: Bool {
        appModel.locationChoice != nil && appModel.locationConfirmed
    }

    private var isTypingCustomLocation: Bool {
        customFieldFocus != nil && appModel.locationChoice == .custom
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Where do you need help?")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                            .padding(.top, 20)

                        currentLocationSection
                        customizeLocationSection
                    }
                    .padding(.horizontal, 24)
                    // Extra room so Confirm can scroll above the keyboard.
                    .padding(.bottom, isTypingCustomLocation ? 160 : 24)
                    .animation(expandAnimation, value: appModel.locationChoice)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: customFieldFocus) { _, field in
                    guard field != nil else { return }
                    scrollConfirmIntoView(using: proxy)
                }
            }

            onboardingBottomBar(title: "Next", enabled: canContinue, action: onContinue)
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            handleAuthorizationChange(status)
        }
        .onChange(of: locationManager.addressLine) { _, address in
            guard let address, appModel.locationChoice == .current else { return }
            appModel.resolvedCurrentAddress = address
        }
        .onChange(of: locationManager.coordinate?.latitude) { _, _ in
            if let coordinate = locationManager.coordinate {
                mapCoordinate = coordinate
            }
        }
    }

    private func scrollConfirmIntoView(using proxy: ScrollViewProxy) {
        // Wait for the keyboard to begin presenting, then jump Confirm into view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.28)) {
                proxy.scrollTo(customConfirmAnchor, anchor: UnitPoint(x: 0.5, y: 0.72))
            }
        }
    }

    // MARK: Sections

    private var currentLocationSection: some View {
        let selected = appModel.locationChoice == .current

        return VStack(alignment: .leading, spacing: 12) {
            locationHeader(
                title: "Use current location",
                titleColor: titleBlue,
                isSelected: selected
            ) {
                selectLocation(.current)
            }

            if selected {
                currentLocationPanel
                    .transition(.opacity)
            }
        }
    }

    private var customizeLocationSection: some View {
        let selected = appModel.locationChoice == .custom

        return VStack(alignment: .leading, spacing: 12) {
            locationHeader(
                title: "Customize location",
                titleColor: Color.black.opacity(0.75),
                isSelected: selected
            ) {
                selectLocation(.custom)
            }

            if selected {
                customizeLocationPanel
                    .transition(.opacity)
            }
        }
    }

    private func locationHeader(
        title: String,
        titleColor: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                OnboardingRadioControl(isSelected: isSelected)

                Image("pinIcon")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(titleColor)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(ServiceRowButtonStyle())
    }

    private var currentLocationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentAddressText)
                .font(.subheadline)
                .foregroundStyle(Theme.darkText)
                .fixedSize(horizontal: false, vertical: true)

            distanceSelector

            // Confirm sits above the map so it stays on the first viewport.
            confirmButton(
                enabled: true,
                isConfirmed: appModel.locationConfirmed && appModel.locationChoice == .current
            ) {
                appModel.resolvedCurrentAddress = currentAddressText
                withAnimation(.easeInOut(duration: 0.2)) {
                    appModel.locationConfirmed = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            locationMapPreview(coordinate: mapCoordinate)
        }
        .padding(.leading, 40)
    }

    private var customizeLocationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Address", text: Binding(
                get: { appModel.customAddress },
                set: {
                    appModel.customAddress = $0
                    appModel.locationConfirmed = false
                }
            ))
            .focused($customFieldFocus, equals: .address)
            .textInputAutocapitalization(.words)
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
                    appModel.locationConfirmed = false
                }
            ))
            .focused($customFieldFocus, equals: .zipcode)
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

            distanceSelector

            confirmButton(
                enabled: !appModel.customAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                isConfirmed: appModel.locationConfirmed && appModel.locationChoice == .custom
            ) {
                customFieldFocus = nil
                appModel.customLocation = [appModel.customAddress, appModel.customZipcode]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                withAnimation(.easeInOut(duration: 0.2)) {
                    appModel.locationConfirmed = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .id(customConfirmAnchor)

            locationMapPreview(coordinate: mapCoordinate)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color(red: 0.8, green: 0.73, blue: 0.73).opacity(0.25), radius: 8, y: 4)
        .padding(.leading, 40)
    }

    private var currentAddressText: String {
        if !appModel.resolvedCurrentAddress.isEmpty {
            return appModel.resolvedCurrentAddress
        }
        return locationManager.addressLine ?? LocationManager.sampleAddress
    }

    private var distanceSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Distance")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                Spacer()
                Text(distanceLabel(for: appModel.searchRadiusMiles))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.brandOrange)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: appModel.searchRadiusMiles)
            }

            Slider(
                value: Binding(
                    get: { appModel.searchRadiusMiles },
                    set: {
                        appModel.searchRadiusMiles = $0
                        appModel.locationConfirmed = false
                    }
                ),
                in: 1...100,
                step: 1
            )
            .tint(Theme.brandOrange)

            HStack {
                Text("1 mile")
                Spacer()
                Text("100 miles")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.darkText)
        }
    }

    private func distanceLabel(for miles: Double) -> String {
        let value = Int(miles.rounded())
        return value == 1 ? "1 mile" : "\(value) miles"
    }

    private func confirmButton(enabled: Bool, isConfirmed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isConfirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                        .symbolEffect(.bounce, value: isConfirmed)
                }
                Text(isConfirmed ? "Confirmed" : "Confirm")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isConfirmed ? Color(red: 0.20, green: 0.68, blue: 0.38) : Theme.brandOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .animation(.easeInOut(duration: 0.2), value: isConfirmed)
        }
        .disabled(!enabled && !isConfirmed)
        .opacity(enabled || isConfirmed ? 1 : 0.5)
    }

    private func locationMapPreview(coordinate: CLLocationCoordinate2D) -> some View {
        LocationMapPreview(
            coordinate: coordinate,
            radiusMiles: appModel.searchRadiusMiles
        )
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Actions

    private func selectLocation(_ choice: LocationChoice) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        customFieldFocus = nil

        // Re-tap collapses in place without scrolling.
        if appModel.locationChoice == choice {
            withAnimation(expandAnimation) {
                appModel.locationChoice = nil
                appModel.locationConfirmed = false
            }
            return
        }

        if choice == .current {
            beginCurrentLocationFlow()
            return
        }

        withAnimation(expandAnimation) {
            appModel.locationChoice = .custom
            appModel.locationConfirmed = false
        }
    }

    private func beginCurrentLocationFlow() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUse()
        case .authorizedAlways, .authorizedWhenInUse:
            expandCurrentLocation()
            locationManager.refreshIfAuthorized()
        case .denied, .restricted:
            // Fall back so the panel still matches the design in simulator / denied states.
            locationManager.useSampleLocation()
            expandCurrentLocation()
        @unknown default:
            locationManager.requestWhenInUse()
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            expandCurrentLocation()
            locationManager.refreshIfAuthorized()
        case .denied, .restricted:
            // User dismissed system prompt with Don't Allow — stay collapsed.
            break
        default:
            break
        }
    }

    private func expandCurrentLocation() {
        withAnimation(expandAnimation) {
            appModel.locationChoice = .current
            appModel.locationConfirmed = false
            if let address = locationManager.addressLine {
                appModel.resolvedCurrentAddress = address
            }
            if locationManager.coordinate == nil {
                locationManager.useSampleLocation()
            }
            if let coordinate = locationManager.coordinate {
                mapCoordinate = coordinate
            }
        }
    }
}

// MARK: - Map preview

private struct LocationMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let radiusMiles: Double

    private var radiusMeters: CLLocationDistance {
        max(radiusMiles, 1) * 1609.34
    }

    private var regionSpanMeters: CLLocationDistance {
        max(radiusMeters * 2.5, 1_200)
    }

    var body: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: regionSpanMeters,
                longitudinalMeters: regionSpanMeters
            )
        )) {
            MapCircle(center: coordinate, radius: radiusMeters)
                .foregroundStyle(Color(red: 0.45, green: 0.72, blue: 0.95).opacity(0.28))
                .stroke(Color(red: 0.35, green: 0.62, blue: 0.90).opacity(0.55), lineWidth: 1)

            Annotation("", coordinate: coordinate, anchor: .bottom) {
                Image("pinIcon")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControlVisibility(.hidden)
        .disabled(true)
        .allowsHitTesting(false)
    }
}


// MARK: - Shared

/// White radio with light gray ring; selected shows an orange center dot.
private struct OnboardingRadioControl: View {
    var isSelected: Bool
    var size: CGFloat = 26

    private var borderColor: Color { Color(red: 0.820, green: 0.820, blue: 0.835) }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
            Circle()
                .stroke(borderColor, lineWidth: 1.5)
            if isSelected {
                Circle()
                    .fill(Theme.brandOrange)
                    .frame(width: size * 0.52, height: size * 0.52)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

private func onboardingBottomBar(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        Divider().opacity(0.01)
        Button(action: action) {
            Text(title.localizedKey)
        }
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
