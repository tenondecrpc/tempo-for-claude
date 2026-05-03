## ADDED Requirements

### Requirement: ClaudeCodeKeychainReader cache TTL should use the same window as the CLI

The `ClaudeCodeKeychainReader` in `Tempo macOS/ClaudeCodeKeychainReader.swift` SHALL reduce its in-memory token cache TTL from 5 minutes (`300` seconds) to 30 seconds, matching the Claude Code CLI's own `KEYCHAIN_CACHE_TTL_MS = 30_000`.

#### Scenario: Cache TTL is 30 seconds

- **WHEN** `ClaudeCodeKeychainReader` reads tokens from the Keychain
- **THEN** the cached value is valid for 30 seconds before requiring a fresh Keychain read

#### Scenario: Cache is invalidated on sign-out

- **WHEN** the user signs out
- **THEN** `invalidateCache()` sets the cache to `nil`, discarding any in-memory tokens (unchanged behavior)

#### Scenario: Cache bypass when tokens are nil

- **WHEN** the Keychain returns no data (e.g., access denied or no credentials stored)
- **THEN** the negative result is NOT cached and the next call retries the Keychain (unchanged behavior - already handled by `denialBackoff`)
