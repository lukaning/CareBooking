import AuthenticationServices
import Foundation
import GoogleSignIn
import UIKit

enum SocialAuthError: LocalizedError {
    case missingWindow
    case cancelled
    case missingEmail
    case invalidCallback
    case googleNotConfigured
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingWindow:
            "Unable to present the sign-in sheet."
        case .cancelled:
            "Sign-in was cancelled."
        case .missingEmail:
            "No email was returned. Try again or use another method."
        case .invalidCallback:
            "Sign-in returned an unexpected response."
        case .googleNotConfigured:
            "Google Sign-In needs an iOS OAuth client ID for bundle com.embelife.app. Add GIDClientID and the reversed client ID URL scheme in Info.plist."
        case .message(let text):
            text
        }
    }
}

struct SocialAuthProfile: Equatable {
    var email: String
    var name: String
    var provider: String
}

/// Native Apple Sign In + Google Sign-In (GIDSignIn).
final class SocialAuthService: NSObject {
    static let shared = SocialAuthService()

    private let appleEmailDefaultsKey = "socialAuth.appleEmails"
    private var appleContinuation: CheckedContinuation<SocialAuthProfile, Error>?
    private var appleController: ASAuthorizationController?

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    @MainActor
    func signInWithApple() async throws -> SocialAuthProfile {
        try await withCheckedThrowingContinuation { continuation in
            appleContinuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            appleController = controller
            controller.performRequests()
        }
    }

    @MainActor
    func signInWithGoogle() async throws -> SocialAuthProfile {
        configureGoogleIfNeeded()

        guard GIDSignIn.sharedInstance.configuration != nil else {
            throw SocialAuthError.googleNotConfigured
        }
        guard let presenter = topViewController() else {
            throw SocialAuthError.missingWindow
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            let profile = result.user.profile
            let email = profile?.email ?? ""
            let name = profile?.name ?? [profile?.givenName, profile?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            guard !email.isEmpty else { throw SocialAuthError.missingEmail }
            return SocialAuthProfile(email: email, name: name, provider: "google")
        } catch {
            throw mappedGoogleError(error)
        }
    }

    private func configureGoogleIfNeeded() {
        if GIDSignIn.sharedInstance.configuration != nil { return }
        guard let clientID = resolvedGoogleClientID() else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    private func resolvedGoogleClientID() -> String? {
        let candidates = [
            Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
            googleServiceInfoClientID()
        ]
        for raw in candidates {
            guard let raw else { continue }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("YOUR_"),
                  !trimmed.hasPrefix("$(")
            else { continue }
            return trimmed
        }
        return nil
    }

    private func googleServiceInfoClientID() -> String? {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) else { return nil }
        return dict["CLIENT_ID"] as? String
    }

    private func mappedGoogleError(_ error: Error) -> Error {
        let nsError = error as NSError
        if nsError.domain == GIDSignInError.errorDomain,
           nsError.code == GIDSignInError.canceled.rawValue {
            return SocialAuthError.cancelled
        }
        if nsError.domain == GIDSignInError.errorDomain {
            return SocialAuthError.message(nsError.localizedDescription)
        }
        return error
    }

    private func storedAppleEmail(for userID: String) -> String? {
        let map = UserDefaults.standard.dictionary(forKey: appleEmailDefaultsKey) as? [String: String]
        return map?[userID]
    }

    private func storeAppleEmail(_ email: String, for userID: String) {
        var map = (UserDefaults.standard.dictionary(forKey: appleEmailDefaultsKey) as? [String: String]) ?? [:]
        map[userID] = email
        UserDefaults.standard.set(map, forKey: appleEmailDefaultsKey)
    }

    private func topWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.flatMap(\.windows).first
    }

    private func topViewController() -> UIViewController? {
        guard let root = topWindow()?.rootViewController else { return nil }
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}

extension SocialAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { appleController = nil }
        guard let continuation = appleContinuation else { return }
        appleContinuation = nil

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: SocialAuthError.invalidCallback)
            return
        }

        let userID = credential.user
        if let email = credential.email, !email.isEmpty {
            storeAppleEmail(email, for: userID)
        }

        let email = credential.email
            ?? storedAppleEmail(for: userID)
            ?? "\(userID.prefix(8))@privaterelay.appleid.com"

        let fullName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
            .trimmingCharacters(in: .whitespacesAndNewlines)

        continuation.resume(
            returning: SocialAuthProfile(
                email: email,
                name: fullName,
                provider: "apple"
            )
        )
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        defer { appleController = nil }
        guard let continuation = appleContinuation else { return }
        appleContinuation = nil

        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            continuation.resume(throwing: SocialAuthError.cancelled)
        } else {
            continuation.resume(throwing: error)
        }
    }
}

extension SocialAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        topWindow() ?? ASPresentationAnchor()
    }
}
