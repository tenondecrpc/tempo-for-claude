## MODIFIED Requirements

### Requirement: Security-scoped bookmarks must move from UserDefaults to Keychain
The macOS security-scoped bookmarks for `~/.claude/` folder access SHALL be migrated from `UserDefaults.standard` to the macOS Keychain (`Security.framework`), matching the Keychain pattern used for OAuth tokens on iOS. Bookmark reads SHALL be cached in memory per app process and keyed by account to prevent repeated Keychain prompts during concurrent startup access.

#### Scenario: Bookmark migration on first launch
- **WHEN** the app launches and finds a `claudeFolderBookmark` in `UserDefaults` but no corresponding Keychain entry
- **THEN** the bookmark data is read from `UserDefaults`, written to Keychain with service `"com.tenondev.tempo.claude.bookmarks"` and account `"claudeFolder"`, cached for the current process, and the `UserDefaults` entry is removed

#### Scenario: Bookmark read from Keychain
- **WHEN** `resolveBookmarkedClaudeURL()` needs the bookmark for the first time in a process
- **THEN** it reads from Keychain using `kSecClassGenericPassword`, `kSecAttrService: "com.tenondev.tempo.claude.bookmarks"`, and `kSecAttrAccount: "claudeFolder"`

#### Scenario: Bookmark read served from cache
- **WHEN** a bookmark account has already been loaded during the current process
- **THEN** subsequent reads for that account reuse the cached result without calling `SecItemCopyMatching`

#### Scenario: Negative bookmark result is cached
- **WHEN** a bookmark account is missing, denied, canceled, or fails to load
- **THEN** subsequent reads for that account during the same process reuse the cached unavailable result instead of immediately querying Keychain again

#### Scenario: Bookmark write to Keychain
- **WHEN** a new or refreshed bookmark needs to be persisted
- **THEN** it is saved to Keychain, not `UserDefaults`, and the in-memory cache for that account is updated

#### Scenario: Bookmark delete clears cache
- **WHEN** a bookmark account is deleted
- **THEN** the Keychain item is removed and the in-memory cache entry for that account is cleared

#### Scenario: Home directory bookmark also cached
- **WHEN** `resolveHomeBookmarkURL()` needs the home directory bookmark
- **THEN** it uses the same per-process cache behavior with account `"homeFolder"`

#### Scenario: Security-scoped access remains operation scoped
- **WHEN** local stats or session ingestion use a resolved bookmark URL
- **THEN** `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()` remain scoped to that operation and are not held open globally

#### Scenario: Keychain accessibility
- **WHEN** bookmarks are saved to Keychain
- **THEN** `kSecAttrAccessible` is set to `kSecAttrAccessibleAfterFirstUnlock` (same as iOS OAuth tokens)
