## Why

The 2026-05-03 security audit identified 9 findings across the Tempo codebase. These range from HIGH severity (OAuth tokens stored in plaintext files on macOS, auth logs with public privacy level) to LOW severity (widget snapshot permissions, Keychain cache TTL). While the OAuth PKCE implementation is sound and no hardcoded secrets were found, several hardening items are needed before App Store distribution and to align macOS credential storage with the iOS side.

## What Changes

- Migrate macOS `CredentialStore` from file-based storage to Keychain
- Change `AuthTrace` log privacy from `.public` to `.private`
- Enforce unconditional OAuth `state` parameter validation on both macOS and iOS
- Add `kSecAttrService` scoping to iOS Keychain entries
- Move macOS security-scoped bookmarks from UserDefaults to Keychain
- Enable App Sandbox entitlement for macOS (App Store builds)
- Hash project directory names in iCloud session data
- Set restrictive POSIX permissions on widget snapshot files
- Reduce `ClaudeCodeKeychainReader` cache TTL from 5 minutes to 30 seconds
- Preserve Claude Code session isolation by using CLI credentials only as read-only fresh access-token fallback; Tempo does not refresh or write Claude Code credentials

## Capabilities

### New Capabilities

- `macos-keychain-credentials`: Migrate macOS OAuth credential storage from plaintext file to Keychain
- `auth-log-privacy`: Restrict AuthTrace log visibility to private privacy level
- `oauth-state-validation`: Enforce unconditional OAuth state parameter validation
- `ios-keychain-scoping`: Scope iOS Keychain entries with `kSecAttrService`
- `bookmark-keychain-storage`: Move macOS security-scoped bookmarks to Keychain
- `macos-app-sandbox`: Enable App Sandbox entitlement for macOS distribution
- `icloud-session-data-sanitization`: Hash project directory names in iCloud session data
- `widget-snapshot-permissions`: Set restrictive POSIX permissions on widget snapshot files
- `keychain-cache-ttl`: Align `ClaudeCodeKeychainReader` cache TTL with CLI behavior

### Modified Capabilities

<!-- No existing specs are being modified; all are new capabilities -->

## Impact

- `Tempo macOS/CredentialStore.swift` -- save/load/delete methods
- `Shared/DevLog.swift` -- Logger privacy level
- `Tempo macOS/MacOSAPIClient.swift` -- `submitOAuthCode`, restore order, and CLI credential fallback behavior
- `Tempo/AnthropicAPIClient.swift` -- `submitOAuthCode` and `KeychainStore` enum
- `Tempo macOS/ClaudeLocalDBReader.swift` -- bookmark storage
- `Tempo macOS/Tempo macOS.entitlements` -- sandbox entitlement
- `Tempo macOS/SessionEventWriter.swift` -- session ID construction
- `Shared/WidgetUsageSnapshot.swift` -- snapshot write path
- `Tempo macOS/ClaudeCodeKeychainReader.swift` -- cache TTL constant
