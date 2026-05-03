## Implementation Tasks

- [x] Add per-process bookmark cache in `BookmarkKeychainStore`.
- [x] Update bookmark save/delete/migration paths to keep the cache coherent.
- [x] Ensure `resolveBookmarkedClaudeURL()` and `resolveHomeBookmarkURL()` use cached bookmark load results while preserving scoped access per operation.
- [x] Remove automatic home directory access request from `WelcomeWindowView.onAppear`.
- [x] Keep folder access available through existing explicit local stats/preferences controls.
- [x] Validate OpenSpec change and build the `Tempo macOS` scheme.
