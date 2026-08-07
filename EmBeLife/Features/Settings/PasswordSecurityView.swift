import SwiftUI

struct PasswordSecurityView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false
    @State private var alertMessage: String?
    @State private var devices = LinkedDevice.samples

    private let iconTint = Color(red: 0.96, green: 0.55, blue: 0.42)
    private let iconBG = Color(red: 1.0, green: 0.90, blue: 0.86)
    private let muted = Color(red: 0.45, green: 0.48, blue: 0.55)
    private let logoutFill = Color(red: 1.0, green: 0.90, blue: 0.88)
    private let cardBG = Color.white
    private let pageBG = Color(red: 0.96, green: 0.96, blue: 0.97)

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                changePasswordCard
                devicesCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(pageBG)
        .navigationTitle("Password & Security")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password & Security", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var changePasswordCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                icon: "lock.fill",
                title: "Change Password"
            )

            Text("Password must be at least 8 characters and include upper case, lower case, a number, and a special character.")
                .font(.subheadline)
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)

            passwordField(
                title: "Current Password",
                text: $currentPassword,
                isVisible: $showCurrent
            )
            passwordField(
                title: "New Password",
                text: $newPassword,
                isVisible: $showNew
            )
            passwordField(
                title: "Confirm New Password",
                text: $confirmPassword,
                isVisible: $showConfirm
            )

            Button {
                submitPasswordChange()
            } label: {
                Text("Change Password")
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
        .padding(18)
        .background(cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    private var devicesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                icon: "desktopcomputer",
                title: "Your Devices"
            )

            Text("Your devices linked to this EmBeLife account.")
                .font(.subheadline)
                .foregroundStyle(muted)

            Button {
                devices = []
                alertMessage = "You have been logged out from all devices."
            } label: {
                Text("Log Out From All Devices")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brandOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(logoutFill)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(devices.isEmpty)
            .opacity(devices.isEmpty ? 0.55 : 1)

            if devices.isEmpty {
                Text("No devices are currently signed in.")
                    .font(.subheadline)
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(devices.enumerated()), id: \.element.id) { index, device in
                        deviceRow(device)
                        if index < devices.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 36, height: 36)
                .background(iconBG)
                .clipShape(Circle())

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.darkText)
        }
    }

    private func passwordField(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundStyle(muted)

            Group {
                if isVisible.wrappedValue {
                    TextField(title, text: text)
                } else {
                    SecureField(title, text: text)
                }
            }
            .font(.body)
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .foregroundStyle(muted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func deviceRow(_ device: LinkedDevice) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: device.systemImage)
                .font(.title3)
                .foregroundStyle(muted)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
                Text("\(device.location)  ·  \(device.dateLabel)  ·  \(device.timeLabel)")
                    .font(.caption)
                    .foregroundStyle(muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private func submitPasswordChange() {
        guard !currentPassword.isEmpty else {
            alertMessage = "Enter your current password."
            return
        }
        guard isValidPassword(newPassword) else {
            alertMessage = "New password must be at least 8 characters and include upper case, lower case, a number, and a special character."
            return
        }
        guard newPassword == confirmPassword else {
            alertMessage = "New password and confirmation do not match."
            return
        }
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        alertMessage = "Password updated successfully."
    }

    private func isValidPassword(_ value: String) -> Bool {
        guard value.count >= 8 else { return false }
        let hasUpper = value.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLower = value.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = value.rangeOfCharacter(from: .decimalDigits) != nil
        let special = CharacterSet.alphanumerics.inverted
        let hasSpecial = value.rangeOfCharacter(from: special) != nil
        return hasUpper && hasLower && hasNumber && hasSpecial
    }
}

private struct LinkedDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let location: String
    let dateLabel: String
    let timeLabel: String
    let systemImage: String

    static let samples: [LinkedDevice] = [
        LinkedDevice(id: "1", name: "iMac Pro 24\"", location: "London, UK", dateLabel: "Aug 12, 2021", timeLabel: "2:30 AM", systemImage: "desktopcomputer"),
        LinkedDevice(id: "2", name: "Macbook Air", location: "London, UK", dateLabel: "Aug 12, 2021", timeLabel: "2:30 AM", systemImage: "laptopcomputer"),
        LinkedDevice(id: "3", name: "iPhone 13", location: "London, UK", dateLabel: "Aug 12, 2021", timeLabel: "2:30 AM", systemImage: "iphone"),
        LinkedDevice(id: "4", name: "iPad Pro", location: "London, UK", dateLabel: "Aug 11, 2021", timeLabel: "9:14 PM", systemImage: "ipad"),
        LinkedDevice(id: "5", name: "Mac Mini", location: "London, UK", dateLabel: "Aug 10, 2021", timeLabel: "11:02 AM", systemImage: "macmini")
    ]
}

#Preview {
    NavigationStack {
        PasswordSecurityView()
    }
}
