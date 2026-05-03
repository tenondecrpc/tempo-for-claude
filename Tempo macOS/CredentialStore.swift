import Foundation
import Security

// MARK: - StoredCredentials

struct StoredCredentials: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var scopes: [String]
}

// MARK: - CredentialStore

enum CredentialStore {

    private static let service = "com.tenondev.tempo.claude.oauth"
    private static let account = "credentials"

    private static var credentialsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/tempo-for-claude/credentials.json")
    }

    static func load() -> StoredCredentials? {
        // Attempt Keychain first
        if let credentials = loadFromKeychain() {
            return credentials
        }
        // Fallback: migrate from legacy file
        guard let credentials = loadFromFile() else { return nil }
        try? saveToKeychain(credentials)
        try? FileManager.default.removeItem(at: credentialsURL)
        return credentials
    }

    static func save(_ credentials: StoredCredentials) throws {
        try saveToKeychain(credentials)
        // Delete legacy file if it exists
        try? FileManager.default.removeItem(at: credentialsURL)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        try? FileManager.default.removeItem(at: credentialsURL)
    }

    /// Returns true if the credentials have a non-expired access token (with a 60s buffer).
    static func isValid(_ credentials: StoredCredentials) -> Bool {
        credentials.expiresAt > Date().addingTimeInterval(60)
    }

    // MARK: - Private

    private static func saveToKeychain(_ credentials: StoredCredentials) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(credentials)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        if updateStatus == errSecSuccess { return }

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess {
            throw CredentialStoreError.keychainSaveFailed(status: addStatus)
        }
    }

    private static func loadFromKeychain() -> StoredCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(StoredCredentials.self, from: data)
    }

    private static func loadFromFile() -> StoredCredentials? {
        let url = credentialsURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(StoredCredentials.self, from: data)
    }
}

enum CredentialStoreError: LocalizedError {
    case keychainSaveFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .keychainSaveFailed(let status):
            return "Failed to save credentials to Keychain (status: \(status))."
        }
    }
}
