## Why

Startup currently performs multiple bookmark Keychain reads from independent local-data paths, which can produce repeated `com.tenondev.tempo.claude.bookmarks` prompts during first-run or migration scenarios. The welcome/auth flow can also mix sign-in with local folder permission checks, making it harder to understand which permission is being requested.

## What Changes

- Cache Tempo bookmark Keychain reads in memory for the current app process, keyed by bookmark account.
- Cache missing, denied, or canceled bookmark reads so concurrent startup paths do not immediately repeat the same Keychain query.
- Keep security-scoped resource access scoped per operation; do not hold folder access open globally.
- Remove automatic home folder access requests from the welcome/auth screen.
- Keep local stats and session ingestion permission requests explicit, using the existing folder-access button patterns where the local data is shown.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `bookmark-keychain-storage`: Bookmark reads use a per-launch in-memory cache and suppress repeated immediate reads for unavailable or denied accounts.
- `welcome-window`: Welcome/auth presentation no longer auto-requests home or folder bookmark access.

## Impact

- `Tempo macOS/ClaudeLocalDBReader.swift`: bookmark Keychain cache, invalidation on save/delete, and diagnostics.
- `Tempo macOS/WelcomeWindow.swift`: remove automatic folder/home access prompt from `onAppear`.
- Existing local stats and preferences access buttons remain the explicit way to request folder access.
- No changes to Tempo OAuth storage, Claude Code CLI credential handling, iCloud paths, entitlements, or widget contracts.
