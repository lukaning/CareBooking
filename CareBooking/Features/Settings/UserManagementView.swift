import SwiftUI

struct UserManagementView: View {
    @Environment(AppModel.self) private var appModel
    @State private var expandedUserIDs: Set<String> = []
    @State private var expandedPermissionKeys: [String: Set<FeatureAccessKey>] = [:]
    @State private var showInvite = false
    @State private var showInfo = false

    private let avatarFill = Color(red: 0.95, green: 0.75, blue: 0.12)
    private let inviteSentColor = Color(red: 0.55, green: 0.48, blue: 0.78)
    private let cardBorder = Color(red: 0.90, green: 0.91, blue: 0.93)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(appModel.managedUsers) { user in
                    userCard(user)
                }

                Text("Only people invited in this list can access")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Button {
                    showInvite = true
                } label: {
                    Label("Invite User", systemImage: "person.badge.plus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Theme.darkText)
                }
                .accessibilityLabel("About user management")
            }
        }
        .sheet(isPresented: $showInvite) {
            InviteUserView()
        }
        .alert("User Management", isPresented: $showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Invite teammates and control what each role can access in CareBooking.")
        }
    }

    @ViewBuilder
    private func userCard(_ user: ManagedTeamUser) -> some View {
        let isExpanded = expandedUserIDs.contains(user.id)

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(user.initials)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(avatarFill)
                    .clipShape(Circle())

                Text(user.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                trailingStatus(user, isExpanded: isExpanded)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                handleRowTap(user)
            }

            if isExpanded, user.role.canExpandPermissions, !user.invitePending {
                Divider().padding(.horizontal, 14)

                FeatureAccessListView(
                    permissions: Binding(
                        get: {
                            appModel.managedUsers.first(where: { $0.id == user.id })?.permissions
                                ?? FeatureAccessKey.defaults(for: user.role)
                        },
                        set: { newValue in
                            let nested = appModel.managedUsers.first(where: { $0.id == user.id })?.nestedPermissions
                                ?? ManagedTeamUser.nestedDefaults()
                            appModel.updateManagedUserPermissions(
                                id: user.id,
                                permissions: newValue,
                                nestedPermissions: nested
                            )
                        }
                    ),
                    nestedPermissions: Binding(
                        get: {
                            appModel.managedUsers.first(where: { $0.id == user.id })?.nestedPermissions
                                ?? ManagedTeamUser.nestedDefaults()
                        },
                        set: { newValue in
                            let permissions = appModel.managedUsers.first(where: { $0.id == user.id })?.permissions
                                ?? FeatureAccessKey.defaults(for: user.role)
                            appModel.updateManagedUserPermissions(
                                id: user.id,
                                permissions: permissions,
                                nestedPermissions: newValue
                            )
                        }
                    ),
                    expandedKeys: Binding(
                        get: { expandedPermissionKeys[user.id] ?? [] },
                        set: { expandedPermissionKeys[user.id] = $0 }
                    )
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func trailingStatus(_ user: ManagedTeamUser, isExpanded: Bool) -> some View {
        if user.invitePending {
            HStack(spacing: 6) {
                Text("Invite sent")
                    .font(.subheadline)
                    .foregroundStyle(inviteSentColor)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
            }
        } else if user.role == .admin {
            HStack(spacing: 6) {
                Text(user.role.displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.darkText)
                    .lineLimit(1)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.darkText)
            }
        } else {
            HStack(spacing: 8) {
                Menu {
                    ForEach(TeamAccessRole.inviteChoices) { role in
                        Button(role.title) {
                            appModel.updateManagedUserRole(id: user.id, role: role)
                        }
                    }
                } label: {
                    Text(user.role.title)
                        .font(.subheadline)
                        .foregroundStyle(Theme.darkText)
                }

                Button {
                    toggleExpanded(user)
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleRowTap(_ user: ManagedTeamUser) {
        toggleExpanded(user)
    }

    private func toggleExpanded(_ user: ManagedTeamUser) {
        guard user.role.canExpandPermissions, !user.invitePending else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedUserIDs.contains(user.id) {
                expandedUserIDs.remove(user.id)
            } else {
                expandedUserIDs.insert(user.id)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserManagementView()
            .environment(AppModel())
    }
}
