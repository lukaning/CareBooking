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
                HeroHeaderImage()

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
                        image: "roleClient",
                        selectedImage: "roleClientSelected"
                    )

                    roleCard(
                        role: .provider,
                        title: "I'm a Provider",
                        subtitle: "Those are usually professionals",
                        image: "roleProvider",
                        selectedImage: "roleProviderSelected"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            onboardingBottomBar(title: "Get Started", enabled: appModel.selectedRole != nil, action: onContinue)
        }
    }

    private func roleCard(
        role: UserRole,
        title: String,
        subtitle: String,
        image: String,
        selectedImage: String
    ) -> some View {
        let selected = appModel.selectedRole == role
        let unselectedBorder = Color(red: 0.886, green: 0.886, blue: 0.902) // #E2E2E6

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
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
                    Text("What kind of help or support do you need?")
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

                    Text(service.title)
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
            Text(option.requiresDescription ? "Describe: \(option.title)" : "Notes: \(option.title)")
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
                Text(group.title)
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
                Text(option.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : Theme.darkText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
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

    @State private var locationManager = LocationManager()
    @State private var mapCoordinate = LocationManager.sampleCoordinate

    private let titleBlue = Color(red: 0.114, green: 0.631, blue: 0.949)
    private let expandAnimation = Animation.easeInOut(duration: 0.2)

    private var canContinue: Bool {
        appModel.locationChoice != nil && appModel.locationConfirmed
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Where do you need help?")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .padding(.top, 28)

                    currentLocationSection
                    customizeLocationSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .animation(expandAnimation, value: appModel.locationChoice)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)

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

    // MARK: Sections

    private var currentLocationSection: some View {
        let selected = appModel.locationChoice == .current

        return VStack(alignment: .leading, spacing: 12) {
            locationHeader(
                title: "Use current location",
                titleColor: titleBlue,
                isSelected: selected,
                showPin: !selected
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
                isSelected: selected,
                showPin: !selected
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
        showPin: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                OnboardingRadioControl(isSelected: isSelected)

                if showPin {
                    Image("pinIcon")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }

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
        VStack(alignment: .leading, spacing: 16) {
            Text(currentAddressText)
                .font(.subheadline)
                .foregroundStyle(Theme.darkText)
                .fixedSize(horizontal: false, vertical: true)

            locationMapPreview(coordinate: mapCoordinate)

            distanceSelector

            confirmButton(enabled: true) {
                appModel.resolvedCurrentAddress = currentAddressText
                appModel.locationConfirmed = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .padding(.leading, 40)
    }

    private var customizeLocationPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Address", text: Binding(
                get: { appModel.customAddress },
                set: {
                    appModel.customAddress = $0
                    appModel.locationConfirmed = false
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
                    appModel.locationConfirmed = false
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

            locationMapPreview(coordinate: mapCoordinate)

            distanceSelector

            confirmButton(enabled: !appModel.customAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                appModel.customLocation = [appModel.customAddress, appModel.customZipcode]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                appModel.locationConfirmed = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
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
            Text("Select Distance")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.darkText)

            Slider(
                value: Binding(
                    get: { appModel.searchRadiusMiles },
                    set: {
                        appModel.searchRadiusMiles = $0
                        appModel.locationConfirmed = false
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
            .foregroundStyle(Theme.darkText)
        }
    }

    private func confirmButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button("Confirm", action: action)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.brandOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)
    }

    private func locationMapPreview(coordinate: CLLocationCoordinate2D) -> some View {
        LocationMapPreview(
            coordinate: coordinate,
            radiusMiles: appModel.searchRadiusMiles
        )
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Actions

    private func selectLocation(_ choice: LocationChoice) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

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
