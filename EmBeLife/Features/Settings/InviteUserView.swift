import SwiftUI

struct InviteUserView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var selectedRole: TeamAccessRole?
    @State private var permissions: [FeatureAccessKey: Bool] = [:]
    @State private var nestedPermissions: [FeatureAccessKey: [NestedFeatureAccess]] = ManagedTeamUser.nestedDefaults()
    @State private var expandedKeys: Set<FeatureAccessKey> = []
    @State private var showSuccess = false
    @State private var invitedDisplayName = ""

    private let labelColor = Color(red: 0.55, green: 0.48, blue: 0.72)
    private let fieldBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let requiredColor = Color(red: 0.93, green: 0.35, blue: 0.45)

    private var canInvite: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedRole != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        inviteField(title: "First Name", text: $firstName, placeholder: "John", required: true)
                        inviteField(title: "Last Name", text: $lastName, placeholder: "Smith", required: true)
                    }

                    inviteField(
                        title: "Email",
                        text: $email,
                        placeholder: "johnsmith@yourdomain.com",
                        required: true,
                        keyboard: .emailAddress,
                        autocapitalization: .never
                    )

                    rolePicker

                    if selectedRole != nil {
                        FeatureAccessListView(
                            permissions: $permissions,
                            nestedPermissions: $nestedPermissions,
                            expandedKeys: $expandedKeys
                        )
                        .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(selectedRole?.summaryBullets ?? defaultBullets, id: \.self) { line in
                            Text("• \(line)")
                                .font(.footnote)
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .padding(.top, 4)

                    Button {
                        sendInvite()
                    } label: {
                        Text("Invite")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.brandOrange.opacity(canInvite ? 1 : 0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canInvite)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .principal) {
                    Text("Invite")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                }
            }
        }
        .overlay {
            if showSuccess {
                InvitationSentOverlay(
                    name: invitedDisplayName,
                    onDismiss: {
                        showSuccess = false
                        dismiss()
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showSuccess)
    }

    private var defaultBullets: [String] {
        [
            "Collaborator can do what what what.",
            "Collaborator can NOT do what what what."
        ]
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Role")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(labelColor)

            Menu {
                ForEach(TeamAccessRole.inviteChoices) { role in
                    Button(role.title) {
                        applyRole(role)
                    }
                }
            } label: {
                HStack {
                    Text(selectedRole?.title ?? "Select the type")
                        .font(.body)
                        .foregroundStyle(selectedRole == nil ? Theme.mutedText : Theme.darkText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(fieldBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func inviteField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        required: Bool = false,
        keyboard: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(labelColor)
                if required {
                    Text("*")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(requiredColor)
                }
            }

            TextField(placeholder, text: text)
                .font(.body)
                .foregroundStyle(Theme.darkText)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(fieldBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func applyRole(_ role: TeamAccessRole) {
        selectedRole = role
        permissions = FeatureAccessKey.defaults(for: role)
        nestedPermissions = ManagedTeamUser.nestedDefaults()
        expandedKeys = []
    }

    private func sendInvite() {
        guard let role = selectedRole else { return }
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        invitedDisplayName = "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespaces)
        appModel.inviteManagedUser(
            firstName: trimmedFirst,
            lastName: trimmedLast,
            email: email,
            role: role,
            permissions: permissions,
            nestedPermissions: nestedPermissions
        )
        showSuccess = true
    }
}

struct InvitationSentOverlay: View {
    let name: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            // Centered card — not a sheet, so it sits mid-screen with even spacing.
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.scaledSystem(size: 56))
                    .foregroundStyle(Color(red: 0.30, green: 0.72, blue: 0.38))

                Text("Invitation Sent")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.darkText)

                Text("An invitation has been sent to \(name.isEmpty ? "their" : name) email address.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button("Done", action: onDismiss)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brandOrange)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .frame(maxWidth: 320)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 10)
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityAddTraits(.isModal)
    }
}

#Preview {
    InviteUserView()
        .environment(AppModel())
}
