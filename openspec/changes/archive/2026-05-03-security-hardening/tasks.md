## 1. macOS Keychain Credentials Migration

- [x] 1.1 Create `KeychainStore` helper in `CredentialStore.swift` with `kSecAttrService: "com.tenondev.tempo.claude.oauth"` and `kSecAttrAccount: "credentials"`
- [x] 1.2 Update `CredentialStore.save(_:)` to write to Keychain instead of file
- [x] 1.3 Update `CredentialStore.load()` to read from Keychain instead of file
- [x] 1.4 Update `CredentialStore.delete()` to remove Keychain entry
- [x] 1.5 Add migration logic: on launch, if no Keychain entry but file exists, read file, write to Keychain, delete file
- [x] 1.6 Verify iOS `KeychainStore` is unchanged (no regression)

## 2. Auth Log Privacy

- [x] 2.1 Change `DevLog.trace("AuthTrace", ...)` to use `privacy: .private` instead of `.public`
- [x] 2.2 Audit all `AuthTrace` call sites to confirm no raw tokens are interpolated
- [x] 2.3 Verify non-auth categories (`UsageTrace`, etc.) remain `.public`

## 3. OAuth State Validation

- [x] 3.1 Update `MacOSAPIClient.submitOAuthCode(_:)` to require `parts.count > 1` and validate state unconditionally
- [x] 3.2 Update `AnthropicAPIClient.submitOAuthCode(_:)` to apply the same unconditional validation
- [x] 3.3 Test that codes without `#` fragment are rejected with appropriate error

## 4. iOS Keychain Scoping

- [x] 4.1 Add `kSecAttrService: "com.tenondev.tempo.claude.oauth"` to `KeychainStore.save(_:forKey:)` queries
- [x] 4.2 Add `kSecAttrService` to `KeychainStore.load(key:)` queries
- [x] 4.3 Add `kSecAttrService` to `KeychainStore.delete(key:)` queries
- [x] 4.4 Verify `kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock` is preserved on creation

## 5. Bookmark Keychain Storage

- [x] 5.1 Create Keychain helper for bookmark storage with `kSecAttrService: "com.tenondev.tempo.claude.bookmarks"`
- [x] 5.2 Add migration: on launch, if UserDefaults has bookmark but Keychain does not, migrate and delete UserDefaults entry
- [x] 5.3 Update `resolveBookmarkedClaudeURL()` to read from Keychain
- [x] 5.4 Update bookmark write path to save to Keychain
- [x] 5.5 Apply same pattern for home directory bookmark (`"homeFolder"` account)

## 6. macOS App Sandbox

- [x] 6.1 Add `com.apple.security.app-sandbox` to `Tempo macOS.entitlements`
- [x] 6.2 Add `com.apple.security.network.client` to `Tempo macOS.entitlements`
- [x] 6.3 Verify existing bookmark and iCloud entitlements are sufficient
- [x] 6.4 Test app functionality with sandbox enabled (OAuth, iCloud, bookmarks, network)

## 7. iCloud Session Data Sanitization

- [x] 7.1 Add SHA-256 hashing utility for project directory names (first 12 hex characters)
- [x] 7.2 Update `SessionEventWriter.parseSessionInfo(from:)` to use hashed directory name in `sessionID`
- [x] 7.3 Handle empty/nil directory name with `"unknown"` fallback
- [x] 7.4 Verify hash is deterministic (same project produces same hash across sessions)

## 8. Widget Snapshot Permissions

- [x] 8.1 Add `FileManager.default.setAttributes([.posixPermissions: 0o600], ...)` after snapshot write in `WidgetUsageSnapshot.swift`
- [x] 8.2 Verify permissions are applied after atomic write completes
- [x] 8.3 Confirm widget extensions can still read the snapshot file

## 9. Keychain Cache TTL

- [x] 9.1 Change `cacheTTL` in `ClaudeCodeKeychainReader.swift` from `5 * 60` (300s) to `30` seconds
- [x] 9.2 Verify `invalidateCache()` still works correctly on sign-out
- [x] 9.3 Confirm negative results are not cached (existing `denialBackoff` behavior)
