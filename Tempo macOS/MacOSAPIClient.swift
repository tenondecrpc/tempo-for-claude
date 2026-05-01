import Foundation
import CryptoKit
import AppKit

// MARK: - MacAuthError

enum MacAuthError: LocalizedError {
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

// MARK: - MacAuthState

@Observable
@MainActor
final class MacAuthState {
    var isAuthenticated = false
    var isAwaitingCode = false
    var requiresExplicitSignIn = false
    var accountEmail: String?
    var authSource: AuthSource = .none

    enum AuthSource: Equatable {
        case none
        case cliSession
        case webOAuth
    }

    init() {
        if ClaudeCodeKeychainReader.hasRestorableSession() {
            isAuthenticated = true
            authSource = .cliSession
        } else if let credentials = CredentialStore.load(), CredentialStore.isValid(credentials) {
            isAuthenticated = true
            authSource = .webOAuth
        }
        accountEmail = DetectedClaudeAccount.load()?.emailAddress
    }
}

// MARK: - DetectedClaudeAccount

struct DetectedClaudeAccount {
    let emailAddress: String?
    let displayName: String?
    var label: String? { emailAddress ?? displayName }

    static func load() -> DetectedClaudeAccount? {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let fileURL = homeURL.appendingPathComponent(".claude.json")

        func readAccount(from url: URL) -> DetectedClaudeAccount? {
            guard let data = try? Data(contentsOf: url) else { return nil }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            struct Profile: Decodable {
                struct OAuthAccount: Decodable {
                    let emailAddress: String?
                    let displayName: String?
                }
                let oauthAccount: OAuthAccount?
            }
            guard let profile = try? decoder.decode(Profile.self, from: data),
                  let account = profile.oauthAccount
            else { return nil }
            let email = account.emailAddress.flatMap { $0.isEmpty ? nil : $0 }
            let name = account.displayName.flatMap { $0.isEmpty ? nil : $0 }
            guard email != nil || name != nil else { return nil }
            return DetectedClaudeAccount(emailAddress: email, displayName: name)
        }

        if let account = readAccount(from: fileURL) {
            return account
        }

        if let account = try? ClaudeLocalDBReader.withHomeDirectoryAccess({ homeDir in
            readAccount(from: homeDir.appendingPathComponent(".claude.json"))
        }) {
            return account
        }

        return nil
    }

    static var isActive: Bool { load() != nil }
}

// MARK: - MacOSAPIClient

@MainActor
final class MacOSAPIClient {

    private enum OAuth {
        static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
        static let redirectURI = "https://platform.claude.com/oauth/code/callback"
        static let authorizationEndpoint = "https://claude.ai/oauth/authorize"
        static let tokenEndpoint = "https://platform.claude.com/v1/oauth/token"
        static let scopes = "user:profile user:inference"
    }

    private enum API {
        static let betaHeader = "oauth-2025-04-20"
    }

    private enum TokenSource: String {
        case cliSession
        case webOAuth
    }

    let authState: MacAuthState
    var onSignOut: (() -> Void)?

    private var codeVerifier: String?
    private var pendingOAuthState: String?

    init(authState: MacAuthState) {
        self.authState = authState
    }

    // MARK: - PKCE

    private func generatePKCE() -> (verifier: String, challenge: String) {
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

    private func buildAuthorizationURL(challenge: String, state: String) -> URL {
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

    // MARK: - Sign In (Task 2.1)

    func startOAuthFlow() {
        let (verifier, challenge) = generatePKCE()
        let state = UUID().uuidString
        codeVerifier = verifier
        pendingOAuthState = state
        let authURL = buildAuthorizationURL(challenge: challenge, state: state)
        NSWorkspace.shared.open(authURL)
        authState.isAwaitingCode = true
    }

    func submitOAuthCode(_ rawCode: String) async throws {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "#", maxSplits: 1).map(String.init)
        let code = parts[0]

        if parts.count > 1 {
            guard parts[1] == pendingOAuthState else {
                clearPendingOAuth()
                throw MacAuthError.invalidCallback
            }
        }

        guard let verifier = codeVerifier else {
            clearPendingOAuth()
            throw MacAuthError.invalidCallback
        }

        let tokens = try await exchangeCode(code, verifier: verifier, state: pendingOAuthState ?? "")
        let credentials = StoredCredentials(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: tokens.expiresAt,
            scopes: OAuth.scopes.components(separatedBy: " ")
        )
        try CredentialStore.save(credentials)
        authState.isAuthenticated = true
        authState.authSource = .webOAuth
        DevLog.trace("AuthTrace", "OAuth code exchange succeeded source=webOAuth expiresAt=\(tokens.expiresAt)")
        clearPendingOAuth()
    }

    private func clearPendingOAuth() {
        codeVerifier = nil
        pendingOAuthState = nil
        authState.isAwaitingCode = false
    }

    // MARK: - Token Exchange

    private struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String
        let expires_in: Int?
    }

    private func exchangeCode(
        _ code: String, verifier: String, state: String
    ) async throws -> (accessToken: String, refreshToken: String, expiresAt: Date) {
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
            throw MacAuthError.tokenExchangeFailed
        }
        let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
        let expiresAt = Date().addingTimeInterval(TimeInterval(tokens.expires_in ?? 3600))
        return (tokens.access_token, tokens.refresh_token, expiresAt)
    }

    // MARK: - Auto-Restore (Task 2.3)

    /// Checks for valid stored credentials and restores the session. Returns true if authenticated.
    func tryRestoreSession() async -> Bool {
        // Primary: CLI keychain tokens
        if let cliTokens = ClaudeCodeKeychainReader.loadTokens(), !cliTokens.accessToken.isEmpty {
            authState.isAuthenticated = true
            authState.authSource = .cliSession

            if ClaudeCodeKeychainReader.isAccessTokenFresh(cliTokens) {
                DevLog.trace("AuthTrace", "Restored authenticated state from fresh CLI session")
            } else if cliTokens.refreshToken?.isEmpty == false {
                DevLog.trace("AuthTrace", "Restored authenticated state from CLI session; access token will be validated before web OAuth fallback")
            } else {
                DevLog.trace("AuthTrace", "Restored authenticated state from CLI access token without refresh token; token will be validated before web OAuth fallback")
            }

            return true
        }

        // Fallback: web OAuth credentials
        guard let credentials = CredentialStore.load() else { return false }
        if CredentialStore.isValid(credentials) {
            authState.isAuthenticated = true
            authState.authSource = .webOAuth
            DevLog.trace("AuthTrace", "Restored authenticated state from valid web OAuth credentials expiresAt=\(credentials.expiresAt)")
            return true
        }
        // Token expired - try refresh
        do {
            _ = try await refreshAccessToken()
            authState.isAuthenticated = true
            authState.authSource = .webOAuth
            DevLog.trace("AuthTrace", "Restored authenticated state after refreshing web OAuth credentials")
            return true
        } catch {
            DevLog.trace("AuthTrace", "Failed to restore authenticated state error=\(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Token Refresh (Task 2.4)

    func refreshAccessToken() async throws -> String {
        guard let credentials = CredentialStore.load(), !credentials.refreshToken.isEmpty else {
            DevLog.trace("AuthTrace", "Cannot refresh web OAuth token because no refresh token is stored")
            signOut()
            throw MacAuthError.noToken
        }
        var request = URLRequest(url: URL(string: OAuth.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "grant_type": "refresh_token",
            "refresh_token": credentials.refreshToken,
            "client_id": OAuth.clientID,
            "scope": OAuth.scopes,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if statusCode == 400 || statusCode == 401 {
            struct ErrorBody: Decodable { let error: String? }
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            if body?.error == "invalid_grant" || statusCode == 401 {
                DevLog.trace("AuthTrace", "Web OAuth refresh failed status=\(statusCode) error=\(body?.error ?? "unknown")")
                signOut()
                throw MacAuthError.refreshFailed
            }
        }
        guard statusCode == 200 else {
            DevLog.trace("AuthTrace", "Web OAuth refresh failed status=\(statusCode)")
            throw MacAuthError.httpError(statusCode)
        }
        struct RefreshResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int?
        }
        let tokens = try JSONDecoder().decode(RefreshResponse.self, from: data)
        var updated = credentials
        updated.accessToken = tokens.access_token
        if let refreshToken = tokens.refresh_token, !refreshToken.isEmpty {
            updated.refreshToken = refreshToken
        }
        updated.expiresAt = Date().addingTimeInterval(TimeInterval(tokens.expires_in ?? 3600))
        try? CredentialStore.save(updated)
        DevLog.trace("AuthTrace", "Web OAuth refresh succeeded expiresAt=\(updated.expiresAt)")
        return tokens.access_token
    }

    // MARK: - Authenticated Requests

    func authenticatedRequest(for url: URL) async throws -> Data {
        if let cliTokens = ClaudeCodeKeychainReader.loadTokens(), !cliTokens.accessToken.isEmpty {
            do {
                return try await authenticatedRequestWithCLITokens(cliTokens, for: url)
            } catch MacAuthError.refreshFailed {
                DevLog.trace("AuthTrace", "CLI token refresh failed; attempting web OAuth fallback")
            } catch MacAuthError.noToken {
                DevLog.trace("AuthTrace", "CLI token unavailable; attempting web OAuth fallback")
            } catch MacAuthError.httpError(401) {
                DevLog.trace("AuthTrace", "CLI token request returned 401; attempting web OAuth fallback")
            } catch {
                throw error
            }
        }

        guard let credentials = CredentialStore.load(), !credentials.accessToken.isEmpty else {
            DevLog.trace("AuthTrace", "Authenticated request failed because no usable token source exists")
            throw MacAuthError.noToken
        }

        return try await authenticatedRequestWithWebCredentials(credentials, for: url)
    }

    private func handleAuthenticatedResponse(
        _ data: Data,
        _ http: HTTPURLResponse,
        source: TokenSource
    ) throws -> Data {
        switch http.statusCode {
        case 200:
            DevLog.trace("AuthTrace", "Authenticated request succeeded source=\(source.rawValue)")
            return data
        case 401:
            DevLog.trace("AuthTrace", "Authenticated request returned 401 source=\(source.rawValue)")
            throw MacAuthError.httpError(401)
        case 429:
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            let retryAfterLabel = retryAfter.map { String($0) } ?? "nil"
            DevLog.trace("AuthTrace", "Authenticated request rate limited source=\(source.rawValue) retryAfter=\(retryAfterLabel)")
            throw MacAuthError.rateLimited(retryAfter: retryAfter)
        default:
            DevLog.trace("AuthTrace", "Authenticated request failed source=\(source.rawValue) status=\(http.statusCode)")
            throw MacAuthError.httpError(http.statusCode)
        }
    }

    private func makeAuthenticatedRequest(token: String, for url: URL) async throws -> (Data, HTTPURLResponse) {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(API.betaHeader, forHTTPHeaderField: "anthropic-beta")
        let (data, response) = try await URLSession.shared.data(for: req)
        return (data, response as! HTTPURLResponse)
    }

    private func authenticatedRequestWithCLITokens(
        _ cliTokens: ClaudeCodeKeychainReader.CLITokens,
        for url: URL
    ) async throws -> Data {
        if let expiresAt = cliTokens.expiresAt {
            let expiryDate = Date(timeIntervalSince1970: expiresAt / 1000.0)
            if expiryDate <= Date().addingTimeInterval(60) {
                DevLog.trace("AuthTrace", "CLI access token appears expired; validating it before refresh")
            }
        }

        do {
            let (data, http) = try await makeAuthenticatedRequest(token: cliTokens.accessToken, for: url)
            return try handleAuthenticatedResponse(data, http, source: .cliSession)
        } catch MacAuthError.httpError(401) {
            guard cliTokens.refreshToken?.isEmpty == false else { throw MacAuthError.httpError(401) }
            DevLog.trace("AuthTrace", "CLI token returned 401; refreshing and retrying once")
            let refreshedToken = try await refreshCLIToken(for: cliTokens)
            let (data, http) = try await makeAuthenticatedRequest(token: refreshedToken, for: url)
            return try handleAuthenticatedResponse(data, http, source: .cliSession)
        }
    }

    private func authenticatedRequestWithWebCredentials(
        _ credentials: StoredCredentials,
        for url: URL
    ) async throws -> Data {
        do {
            let (data, http) = try await makeAuthenticatedRequest(token: credentials.accessToken, for: url)
            return try handleAuthenticatedResponse(data, http, source: .webOAuth)
        } catch MacAuthError.httpError(401) {
            DevLog.trace("AuthTrace", "Web OAuth token returned 401; refreshing and retrying once")
            let refreshedToken = try await refreshAccessToken()
            let (data, http) = try await makeAuthenticatedRequest(token: refreshedToken, for: url)
            return try handleAuthenticatedResponse(data, http, source: .webOAuth)
        }
    }

    private func refreshCLIToken(for cliTokens: ClaudeCodeKeychainReader.CLITokens) async throws -> String {
        guard let refreshToken = cliTokens.refreshToken, !refreshToken.isEmpty else {
            DevLog.trace("AuthTrace", "Cannot refresh CLI token because no refresh token is stored")
            throw MacAuthError.noToken
        }

        let clientID = cliTokens.clientId.flatMap { $0.isEmpty ? nil : $0 } ?? OAuth.clientID
        let scopes = cliTokens.scopes.isEmpty ? OAuth.scopes : cliTokens.scopes.joined(separator: " ")
        var request = URLRequest(url: URL(string: OAuth.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID,
            "scope": scopes,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 else {
            struct ErrorBody: Decodable { let error: String? }
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            DevLog.trace(
                "AuthTrace",
                "CLI token refresh failed status=\(statusCode) error=\(body?.error ?? "unknown") hasClientId=\(cliTokens.clientId?.isEmpty == false) scopeCount=\(cliTokens.scopes.count)"
            )
            throw MacAuthError.refreshFailed
        }
        struct RefreshResponse: Decodable { let access_token: String; let expires_in: Int? }
        let tokens = try JSONDecoder().decode(RefreshResponse.self, from: data)
        DevLog.trace("AuthTrace", "CLI token refresh succeeded")
        return tokens.access_token
    }

    // MARK: - Sign Out (Task 2.5)

    func signOut() {
        CredentialStore.delete()
        authState.isAuthenticated = false
        authState.isAwaitingCode = false
        authState.requiresExplicitSignIn = true
        authState.authSource = .none
        DevLog.trace("AuthTrace", "Signed out and cleared stored web OAuth credentials")
        onSignOut?()
    }
}
