import Foundation
import AuthenticationServices
import CryptoKit
import Security
import UIKit

// MARK: - Keychain

private enum KeychainKey {
    static let accessToken = "anthropic.access_token"
    static let refreshToken = "anthropic.refresh_token"
}

private enum KeychainStore {
    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case noToken
    case invalidCallback
    case tokenExchangeFailed
    case refreshFailed
    case rateLimited(retryAfter: TimeInterval?)
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noToken: return "No authentication token. Please sign in."
        case .invalidCallback: return "Invalid authorization callback."
        case .tokenExchangeFailed: return "Failed to exchange authorization code."
        case .refreshFailed: return "Session expired. Please sign in again."
        case .rateLimited(let s): return s.map { "Rate limited. Retry after \(Int($0))s." } ?? "Rate limited."
        case .httpError(let code): return "HTTP error \(code)."
        }
    }
}

// MARK: - AuthState

@Observable
@MainActor
final class AuthState {
    var isAuthenticated = false

    init() {
        isAuthenticated = KeychainStore.load(key: KeychainKey.accessToken) != nil
    }
}

// MARK: - AnthropicAPIClient

@MainActor
final class AnthropicAPIClient: NSObject {

    private enum OAuth {
        static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
        static let redirectURI = "https://platform.claude.com/oauth/code/callback"
        static let authorizationEndpoint = "https://claude.ai/oauth/authorize"
        static let tokenEndpoint = "https://platform.claude.com/v1/oauth/token"
        static let scopes = "user:profile user:inference"
    }

    private enum API {
        static let usageEndpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        static let betaHeader = "oauth-2025-04-20"
    }

    let authState: AuthState
    var onSignOut: (() -> Void)?

    // Keeps ASWebAuthenticationSession alive for the duration of sign-in
    private var authSession: AnyObject?

    init(authState: AuthState) {
        self.authState = authState
        super.init()
    }

    // MARK: - PKCE (Tasks 2.1)

    func generatePKCE() -> (verifier: String, challenge: String) {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let verifier = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let hash = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return (verifier, challenge)
    }

    // MARK: - Authorization URL (Task 2.2)

    func buildAuthorizationURL(challenge: String, state: String) -> URL {
        var components = URLComponents(string: OAuth.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "code", value: "true"),
            URLQueryItem(name: "client_id", value: OAuth.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: OAuth.redirectURI),
            URLQueryItem(name: "scope", value: OAuth.scopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }

    // MARK: - Sign In (Task 2.3)

    func signIn() async throws {
        let (verifier, challenge) = generatePKCE()
        let state = UUID().uuidString
        let authURL = buildAuthorizationURL(challenge: challenge, state: state)

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session: ASWebAuthenticationSession
            if #available(iOS 17.4, *) {
                // Uses HTTPS callback interception — no Universal Links required
                session = ASWebAuthenticationSession(
                    url: authURL,
                    callback: .https(host: "platform.claude.com", path: "/oauth/code/callback")
                ) { url, error in
                    if let error { continuation.resume(throwing: error) }
                    else if let url { continuation.resume(returning: url) }
                    else { continuation.resume(throwing: AuthError.invalidCallback) }
                }
            } else {
                session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "https"
                ) { url, error in
                    if let error { continuation.resume(throwing: error) }
                    else if let url { continuation.resume(returning: url) }
                    else { continuation.resume(throwing: AuthError.invalidCallback) }
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            session.start()
        }
        authSession = nil

        // Parse code and state: try query params first, then <code>#<state> fragment format
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        var code: String?
        var returnedState: String?

        if let q = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            code = q
            returnedState = components?.queryItems?.first(where: { $0.name == "state" })?.value
        } else if let fragment = callbackURL.fragment, !fragment.isEmpty {
            let parts = fragment.split(separator: "#", maxSplits: 1).map(String.init)
            code = parts.first
            returnedState = parts.count > 1 ? parts[1] : nil
        }

        guard let code else { throw AuthError.invalidCallback }

        let (accessToken, refreshToken) = try await exchangeCode(
            code,
            verifier: verifier,
            state: returnedState ?? state
        )
        KeychainStore.save(accessToken, forKey: KeychainKey.accessToken)
        KeychainStore.save(refreshToken, forKey: KeychainKey.refreshToken)
        authState.isAuthenticated = true
    }

    // MARK: - Token Exchange (Task 2.4)

    func exchangeCode(_ code: String, verifier: String, state: String) async throws -> (accessToken: String, refreshToken: String) {
        var request = URLRequest(url: URL(string: OAuth.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "grant_type": "authorization_code",
            "code": code,
            "state": state,
            "client_id": OAuth.clientID,
            "redirect_uri": OAuth.redirectURI,
            "code_verifier": verifier,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }
        struct TokenResponse: Decodable { let access_token: String; let refresh_token: String }
        let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
        return (tokens.access_token, tokens.refresh_token)
    }

    // MARK: - Token Refresh (Task 2.5)

    func refreshAccessToken() async throws -> String {
        guard let refreshToken = KeychainStore.load(key: KeychainKey.refreshToken) else {
            signOut(); throw AuthError.noToken
        }
        var request = URLRequest(url: URL(string: OAuth.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": OAuth.clientID,
            "scope": OAuth.scopes,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if statusCode == 400 || statusCode == 401 {
            struct ErrorBody: Decodable { let error: String? }
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            if body?.error == "invalid_grant" || statusCode == 401 {
                signOut(); throw AuthError.refreshFailed
            }
        }
        guard statusCode == 200 else { throw AuthError.httpError(statusCode) }
        struct TokenResponse: Decodable { let access_token: String }
        let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
        KeychainStore.save(tokens.access_token, forKey: KeychainKey.accessToken)
        return tokens.access_token
    }

    // MARK: - Authenticated Requests (Task 3.1)

    func authenticatedRequest(for url: URL) async throws -> Data {
        guard var accessToken = KeychainStore.load(key: KeychainKey.accessToken) else {
            throw AuthError.noToken
        }

        func makeRequest(token: String) async throws -> (Data, HTTPURLResponse) {
            var req = URLRequest(url: url)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(API.betaHeader, forHTTPHeaderField: "anthropic-beta")
            let (data, response) = try await URLSession.shared.data(for: req)
            return (data, response as! HTTPURLResponse)
        }

        var (data, http) = try await makeRequest(token: accessToken)

        if http.statusCode == 401 {
            accessToken = try await refreshAccessToken()
            (data, http) = try await makeRequest(token: accessToken)
        }

        switch http.statusCode {
        case 200:
            return data
        case 429:
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw AuthError.rateLimited(retryAfter: retryAfter)
        default:
            throw AuthError.httpError(http.statusCode)
        }
    }

    // MARK: - Sign Out (Task 3.2)

    func signOut() {
        KeychainStore.delete(key: KeychainKey.accessToken)
        KeychainStore.delete(key: KeychainKey.refreshToken)
        authState.isAuthenticated = false
        onSignOut?()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding (Task 2.3)

extension AnthropicAPIClient: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // System always calls this on the main thread
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first(where: \.isKeyWindow) ?? UIWindow()
        }
    }
}
