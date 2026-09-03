import AuthenticationServices
import Foundation
import UIKit

enum SocialAuthError: LocalizedError {
    case missingWindow
    case cancelled
    case missingToken
    case missingEmail
    case invalidCallback
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingWindow:
            "Unable to present the sign-in sheet."
        case .cancelled:
            "Sign-in was cancelled."
        case .missingToken:
            "Sign-in did not return a session. Enable Google in Supabase Auth → Providers, and add redirect URL com.embelife.app://auth-callback."
        case .missingEmail:
            "No email was returned. Try again or use another method."
        case .invalidCallback:
            "Sign-in returned an unexpected response."
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

/// Native Apple Sign In + Google via Supabase OAuth.
final class SocialAuthService: NSObject {
    static let shared = SocialAuthService()

    private let supabaseProjectRef = "jmtqytfbzgfvcabjqimw"
    private let redirectScheme = "com.embelife.app"
    private let redirectURL = "com.embelife.app://auth-callback"
    private let appleEmailDefaultsKey = "socialAuth.appleEmails"

    private var appleContinuation: CheckedContinuation<SocialAuthProfile, Error>?
    private var appleController: ASAuthorizationController?
    private var webSession: ASWebAuthenticationSession?

    private var supabaseAuthorizeBase: URL {
        URL(string: "https://\(supabaseProjectRef).supabase.co/auth/v1/authorize")!
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
        var components = URLComponents(url: supabaseAuthorizeBase, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURL)
        ]
        guard let url = components.url else {
            throw SocialAuthError.invalidCallback
        }

        let callbackURL = try await startWebAuth(url: url)
        return try profile(from: callbackURL, provider: "google")
    }

    @MainActor
    private func startWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: redirectScheme
            ) { [weak self] callbackURL, error in
                self?.webSession = nil
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: SocialAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: SocialAuthError.invalidCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            webSession = session
            if !session.start() {
                continuation.resume(throwing: SocialAuthError.missingWindow)
            }
        }
    }

    private func profile(from callbackURL: URL, provider: String) throws -> SocialAuthProfile {
        let params = Self.queryItems(from: callbackURL)
        if let errorDescription = params["error_description"] ?? params["error"] {
            throw SocialAuthError.message(errorDescription.replacingOccurrences(of: "+", with: " "))
        }
        guard let accessToken = params["access_token"], !accessToken.isEmpty else {
            throw SocialAuthError.missingToken
        }

        let claims = Self.decodeJWTPayload(accessToken) ?? [:]
        let metadata = claims["user_metadata"] as? [String: Any]
        let email = (claims["email"] as? String)
            ?? (metadata?["email"] as? String)
            ?? ""
        let name = (metadata?["full_name"] as? String)
            ?? (metadata?["name"] as? String)
            ?? [metadata?["given_name"] as? String, metadata?["family_name"] as? String]
            .compactMap { $0 }
            .joined(separator: " ")

        guard !email.isEmpty else { throw SocialAuthError.missingEmail }
        return SocialAuthProfile(email: email, name: name, provider: provider)
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

    private static func queryItems(from url: URL) -> [String: String] {
        var items: [String: String] = [:]
        for part in [url.fragment ?? "", url.query ?? ""] where !part.isEmpty {
            for pair in part.split(separator: "&") {
                let pieces = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard pieces.count == 2 else { continue }
                let key = pieces[0].removingPercentEncoding ?? pieces[0]
                let value = pieces[1].removingPercentEncoding ?? pieces[1]
                items[key] = value
            }
        }
        return items
    }

    private static func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
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

extension SocialAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        topWindow() ?? ASPresentationAnchor()
    }
}
