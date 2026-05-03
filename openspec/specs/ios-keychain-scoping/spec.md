## Purpose

Define stable Keychain scoping for iOS OAuth credentials.

## Requirements

### Requirement: iOS Keychain entries must include `kSecAttrService`
The iOS `KeychainStore` (in `Tempo/AnthropicAPIClient.swift`) SHALL scope Keychain items with `kSecAttrService` set to `"com.tenondev.tempo.claude.oauth"` on all create, read, update, and delete operations.

#### Scenario: Save includes service attribute
- **WHEN** `KeychainStore.save(_:forKey:)` creates or updates a Keychain item
- **THEN** the query dictionary includes `kSecAttrService: "com.tenondev.tempo.claude.oauth"` alongside the existing `kSecClass` and `kSecAttrAccount` keys

#### Scenario: Load includes service attribute
- **WHEN** `KeychainStore.load(key:)` queries the Keychain
- **THEN** the query dictionary includes `kSecAttrService: "com.tenondev.tempo.claude.oauth"`

#### Scenario: Delete includes service attribute
- **WHEN** `KeychainStore.delete(key:)` removes a Keychain item
- **THEN** the query dictionary includes `kSecAttrService: "com.tenondev.tempo.claude.oauth"`

#### Scenario: Accessibility is preserved
- **WHEN** the service attribute is added
- **THEN** `kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock` remains set on item creation (unchanged behavior)
