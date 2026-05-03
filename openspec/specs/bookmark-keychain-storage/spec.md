## Purpose

Define secure local storage for macOS security-scoped bookmarks.

## Requirements

### Requirement: Security-scoped bookmarks must move from UserDefaults to Keychain
The macOS security-scoped bookmarks for `~/.claude/` folder access SHALL be migrated from `UserDefaults.standard` to the macOS Keychain (`Security.framework`), matching the Keychain pattern used for OAuth tokens on iOS.

#### Scenario: Bookmark migration on first launch
- **WHEN** the app launches and finds a `claudeFolderBookmark` in `UserDefaults` but no corresponding Keychain entry
- **THEN** the bookmark data is read from `UserDefaults`, written to Keychain with service `"com.tenondev.tempo.claude.bookmarks"` and account `"claudeFolder"`, and the `UserDefaults` entry is removed

#### Scenario: Bookmark read from Keychain
- **WHEN** `resolveBookmarkedClaudeURL()` needs the bookmark
- **THEN** it reads from Keychain instead of `UserDefaults`, using `kSecClassGenericPassword` with `kSecAttrService: "com.tenondev.tempo.claude.bookmarks"` and `kSecAttrAccount: "claudeFolder"`

#### Scenario: Bookmark write to Keychain
- **WHEN** a new or refreshed bookmark needs to be persisted
- **THEN** it is saved to Keychain, not `UserDefaults`

#### Scenario: Home directory bookmark also migrated
- **WHEN** `resolveHomeBookmarkURL()` needs the home directory bookmark
- **THEN** it reads from Keychain with account `"homeFolder"` following the same pattern

#### Scenario: Keychain accessibility
- **WHEN** bookmarks are saved to Keychain
- **THEN** `kSecAttrAccessible` is set to `kSecAttrAccessibleAfterFirstUnlock` (same as iOS OAuth tokens)
