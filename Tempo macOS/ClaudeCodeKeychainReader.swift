import Foundation
import Security

// MARK: - ClaudeCodeKeychainReader

/// Reads OAuth tokens from the Claude Code CLI's macOS Keychain entry.
/// Service: "Claude Code-credentials", Account: $USER
enum ClaudeCodeKeychainReader {

    private static let serviceName = "Claude Code-credentials"

    struct CLITokens: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: TimeInterval?
        let scopes: [String]
        let subscriptionType: String?
        let clientId: String?
    }

    struct SecureStorageData: Codable {
        let claudeAiOauth: CLITokens?
    }

    /// Returns the CLI OAuth tokens if available in the macOS Keychain.
    static func loadTokens() -> CLITokens? {
        if let tokens = loadTokensWithSecurityFramework() {
            DevLog.trace("AuthTrace", "Loaded Claude Code CLI tokens via Security framework")
            return tokens
        }

        if let tokens = loadTokensWithSecurityTool() {
            DevLog.trace("AuthTrace", "Loaded Claude Code CLI tokens via security tool fallback")
            return tokens
        }

        DevLog.trace("AuthTrace", "No Claude Code CLI tokens found in Keychain")
        return nil
    }

    private static func loadTokensWithSecurityFramework() -> CLITokens? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: NSUserName(),
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            DevLog.trace("AuthTrace", "Security framework Claude Code token lookup failed status=\(status)")
            return nil
        }

        return decodeTokens(from: data)
    }

    private static func loadTokensWithSecurityTool() -> CLITokens? {
        let account = NSUserName()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = [
            "find-generic-password",
            "-a", account,
            "-w",
            "-s", serviceName,
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return decodeTokens(from: data)
        } catch {
            return nil
        }
    }

    private static func decodeTokens(from data: Data) -> CLITokens? {
        let jsonData: Data
        if let string = String(data: data, encoding: .utf8) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            jsonData = Data(trimmed.utf8)
        } else {
            jsonData = data
        }

        let storage = try? JSONDecoder().decode(SecureStorageData.self, from: jsonData)
        return storage?.claudeAiOauth
    }

    /// Returns true if valid CLI OAuth tokens exist in the keychain.
    static func hasValidSession() -> Bool {
        guard let tokens = loadTokens() else { return false }
        guard let accessToken = tokens.accessToken.isEmpty ? nil : tokens.accessToken else { return false }
        _ = accessToken
        return isAccessTokenFresh(tokens)
    }

    /// Returns true when Claude Code has enough local state to restore without a web login.
    static func hasRestorableSession() -> Bool {
        guard let tokens = loadTokens() else { return false }
        return !tokens.accessToken.isEmpty
    }

    static func isAccessTokenFresh(_ tokens: CLITokens) -> Bool {
        if let expiresAt = tokens.expiresAt {
            let expiryDate = Date(timeIntervalSince1970: expiresAt / 1000.0)
            return expiryDate > Date().addingTimeInterval(60)
        }
        return true
    }
}
