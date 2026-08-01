import SwiftUI

struct ProfileDetailEditView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft: UserProfile
    @State private var isAddingMember = false
    @State private var newMemberFirst = ""
    @State private var newMemberLast = ""
    @State private var expandedMemberID: UUID?
    @State private var showLanguagePicker = false

    private let availableLanguages = ["English", "Spain", "French", "Chinese", "Portuguese"]

    init(profile: UserProfile) {
        _draft = State(initialValue: profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                contactSection
                languageSection
                familySection
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Profile Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        appModel.publishProfile(draft)
                    }
                    dismiss()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.brandOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .disabled(!draft.hasMinimumContact)
                .opacity(draft.hasMinimumContact ? 1 : 0.45)
            }
        }
        .confirmationDialog("Add language", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            ForEach(availableLanguages.filter { !draft.languages.contains($0) }, id: \.self) { language in
                Button(language) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        draft.languages.append(language)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Contact

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.224, green: 0.263, blue: 0.369))

            HStack(alignment: .top, spacing: 12) {
                profileField(title: "First Name", text: $draft.firstName, required: true, placeholder: "First name")
                profileField(title: "Middle Name", text: $draft.middleName, required: false, placeholder: "Middle")
            }

            profileField(title: "Last Name", text: $draft.lastName, required: true, placeholder: "Last name")

            VStack(alignment: .leading, spacing: 6) {
                requiredLabel("Address")
                HStack {
                    TextField("Enter address", text: $draft.address)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color(red: 0.349, green: 0.255, blue: 0.451))
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Theme.grayscale60)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.902, green: 0.910, blue: 0.925), lineWidth: 1.5)
                )
            }

            profileField(title: "Email", text: $draft.email, required: true, placeholder: "Enter your email", keyboard: .emailAddress)
            profileField(title: "Mobile Number", text: $draft.mobile, required: true, placeholder: "Enter number", keyboard: .phonePad)
        }
    }

    // MARK: - Languages

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language Preference")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.224, green: 0.263, blue: 0.369))

            Text("Language(s) Spoken")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.561, green: 0.565, blue: 0.737))

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(draft.languages, id: \.self) { language in
                            languageChip(language)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                }

                Button {
                    showLanguagePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.grayscale60)
                        .frame(width: 36, height: 36)
                        .background(Color(red: 0.941, green: 0.941, blue: 0.941))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.902, green: 0.910, blue: 0.925), lineWidth: 1.5)
            )
        }
    }

    private func languageChip(_ language: String) -> some View {
        HStack(spacing: 6) {
            Text(language)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    draft.languages.removeAll { $0 == language }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.brandOrange)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    // MARK: - Family

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Family & Friends")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.224, green: 0.263, blue: 0.369))

            if !draft.familyMembers.isEmpty {
                Text("Member List")
                    .font(.subheadline)
                    .foregroundStyle(Theme.grayscale70)

                ForEach(draft.familyMembers) { member in
                    memberRow(member)
                }
            }

            if isAddingMember {
                addMemberCard
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isAddingMember = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(Color(red: 0.902, green: 0.910, blue: 0.925), lineWidth: 1.5)
                                .frame(width: 36, height: 36)
                            Text("+")
                                .font(.title3)
                                .foregroundStyle(Color(red: 0.412, green: 0.412, blue: 0.455))
                        }
                        Text("Adding member")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(red: 0.067, green: 0.067, blue: 0.067))
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func memberRow(_ member: FamilyMember) -> some View {
        let expanded = expandedMemberID == member.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(member.avatarStyle.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(member.monogram)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        expandedMemberID = expanded ? nil : member.id
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(member.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.grayscale60)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        draft.familyMembers.removeAll { $0.id == member.id }
                        if expandedMemberID == member.id { expandedMemberID = nil }
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            if expanded {
                memberDetailCard(member)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }

    private func memberDetailCard(_ member: FamilyMember) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Service")
                    .font(.caption)
                    .foregroundStyle(Theme.grayscale70)
                ForEach(member.preferredServices, id: \.self) { service in
                    Text(service)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1)
                .padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred time")
                    .font(.caption)
                    .foregroundStyle(Theme.grayscale70)
                ForEach(member.preferredTimes, id: \.self) { time in
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(Theme.grayscale60)
                        Text(time)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var addMemberCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                profileField(title: "First Name", text: $newMemberFirst, required: false, placeholder: "First")
                profileField(title: "Last Name", text: $newMemberLast, required: false, placeholder: "Last")
            }

            Text("Or Choose from account")
                .font(.subheadline)
                .foregroundStyle(Theme.grayscale70)
                .frame(maxWidth: .infinity)

            Menu {
                ForEach(FamilyMember.existingAccounts) { account in
                    Button(account.displayName) {
                        addExisting(account)
                    }
                }
            } label: {
                HStack {
                    Text("Select existing user")
                        .foregroundStyle(Theme.grayscale60)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Theme.grayscale60)
                }
                .padding(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.902, green: 0.910, blue: 0.925), lineWidth: 1.5)
                )
            }

            HStack {
                Button("Cancel") {
                    withAnimation {
                        isAddingMember = false
                        newMemberFirst = ""
                        newMemberLast = ""
                    }
                }
                .foregroundStyle(Theme.grayscale70)

                Spacer()

                Button("Add") {
                    addManualMember()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(canAddManual ? Theme.brandOrange : Theme.grayscale60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(!canAddManual)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var canAddManual: Bool {
        !newMemberFirst.trimmingCharacters(in: .whitespaces).isEmpty
            && !newMemberLast.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addManualMember() {
        let member = FamilyMember(
            firstName: newMemberFirst.trimmingCharacters(in: .whitespaces),
            lastName: newMemberLast.trimmingCharacters(in: .whitespaces),
            preferredServices: ["Personal care/ hygiene"],
            preferredTimes: ["8am – 10am"],
            avatarStyle: .next(after: draft.familyMembers.count)
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            draft.familyMembers.append(member)
            expandedMemberID = member.id
            isAddingMember = false
            newMemberFirst = ""
            newMemberLast = ""
        }
    }

    private func addExisting(_ account: FamilyMember) {
        var copy = account
        copy = FamilyMember(
            firstName: account.firstName,
            lastName: account.lastName,
            preferredServices: account.preferredServices,
            preferredTimes: account.preferredTimes,
            avatarStyle: account.avatarStyle
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            draft.familyMembers.append(copy)
            expandedMemberID = copy.id
            isAddingMember = false
        }
    }

    // MARK: - Field helpers

    private func profileField(
        title: String,
        text: Binding<String>,
        required: Bool,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if required {
                requiredLabel(title)
            } else {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(red: 0.561, green: 0.565, blue: 0.737))
            }

            TextField(placeholder, text: text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(red: 0.349, green: 0.255, blue: 0.451))
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.902, green: 0.910, blue: 0.925), lineWidth: 1.5)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.561, green: 0.565, blue: 0.737))
            Text("*")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 1.0, green: 0.29, blue: 0.63))
        }
    }
}
