## Purpose

Define secure macOS storage for Tempo-owned OAuth credentials.

## Requirements

### Requirement: macOS OAuth credentials must migrate from file to Keychain
The macOS `CredentialStore` (`Tempo macOS/CredentialStore.swift`) SHALL be migrated from file-based storage (`~/.config/tempo-for-claude/credentials.json`, 0o600) to the macOS Keychain (`Security.framework`). The iOS side already stores OAuth tokens in Keychain correctly via `AnthropicAPIClient.swift`; macOS SHALL follow the same pattern.

#### Scenario: Keychain is the primary store
- **WHEN** `CredentialStore.save(_:)` is called
- **THEN** credentials are written to Keychain with `kSecClassGenericPassword`, `kSecAttrService: "com.tenondev.tempo.claude.oauth"`, `kSecAttrAccount: "credentials"`, and `kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock`

#### Scenario: Load reads from Keychain
- **WHEN** `CredentialStore.load()` is called
- **THEN** it queries Keychain with `kSecAttrService: "com.tenondev.tempo.claude.oauth"` and `kSecAttrAccount: "credentials"` and decodes the stored `StoredCredentials`

#### Scenario: Delete removes Keychain entry
- **WHEN** `CredentialStore.delete()` is called
- **THEN** the Keychain item is removed

#### Scenario: Migration from legacy file
- **WHEN** the app launches and finds no Keychain entry but `~/.config/tempo-for-claude/credentials.json` exists
- **THEN** the file is read, its contents are written to Keychain, the file is deleted, and `load()` returns the migrated credentials

#### Scenario: File is deleted after migration
- **WHEN** migration completes successfully
- **THEN** `~/.config/tempo-for-claude/credentials.json` no longer exists on disk

#### Scenario: No regression for iOS
- **WHEN** the macOS Keychain migration is implemented
- **THEN** the iOS `KeychainStore` in `Tempo/AnthropicAPIClient.swift` is unchanged (iOS already uses Keychain correctly)
