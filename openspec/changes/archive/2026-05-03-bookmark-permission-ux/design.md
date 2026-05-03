## Context

Tempo stores security-scoped bookmarks in the macOS Keychain under service `com.tenondev.tempo.claude.bookmarks`. At launch, multiple consumers can resolve the same bookmark nearly simultaneously: local stats, session completion ingestion, account display, and home access checks. Diagnostic logs showed duplicate `claudeFolder` reads and repeated `homeFolder` checks during startup.

The welcome window also currently checks home bookmark state and may schedule `requestHomeDirectoryAccess()` from `onAppear`. This ties local folder permissions to authentication even though OAuth/CLI auth and local file access are separate concerns.

## Goals / Non-Goals

**Goals:**

- Avoid repeated Keychain reads for the same bookmark account during one process lifetime.
- Preserve existing bookmark persistence and migration behavior.
- Keep `startAccessingSecurityScopedResource()` scoped to each file operation.
- Make folder access user-initiated from local-data surfaces rather than automatic from welcome/auth.
- Preserve the current Claude Code CLI read-only auth fallback.

**Non-Goals:**

- Do not change Tempo OAuth credential storage.
- Do not change or delete Claude Code CLI credentials.
- Do not remove local stats or session ingestion.
- Do not introduce a new permission onboarding flow beyond removing the automatic welcome prompt.

## Decisions

1. Cache bookmark data, not resolved URLs.

   Bookmark data is small and stable for the process lifetime. Resolving a URL remains cheap and lets each operation independently call `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()`.

2. Cache negative results for the launch.

   If a bookmark is missing, denied, canceled, or fails to load, the cache records that result. This prevents parallel startup paths from repeatedly querying Keychain and showing duplicate prompts. Saving or deleting a bookmark invalidates or updates the cache.

3. Keep migration before cache population.

   `migrateIfNeeded(defaultsKey:account:)` still checks Keychain before reading legacy `UserDefaults`. After migration succeeds, `saveBookmark` updates the cache.

4. Remove the welcome-window automatic home access request.

   `DetectedClaudeAccount.load()` remains best-effort. If it cannot read `.claude.json` through the home bookmark, the welcome view simply omits the detected label. Folder access remains available where local stats and notification settings already explain why it is needed.

## Risks / Trade-offs

- Cached missing state could hide a bookmark that is created outside the normal save path during the same launch -> The app creates bookmarks through `saveBookmark`, which updates the cache. External Keychain edits can be picked up on next launch.
- Negative caching could delay retry after a user denial -> This is intentional for startup prompt suppression; explicit UI actions that save a bookmark update the cache immediately.
- Removing automatic home prompt may reduce detected-account labels in welcome -> Authentication still works; the label is display-only and should not trigger a permission prompt.
