## 1. Xcode Project Setup

- [ ] 1.1 Add new macOS app target "ClaudeTracker macOS" to `ClaudeTracker.xcodeproj` — SwiftUI lifecycle, menu bar app (no Dock icon via `LSUIElement = YES`)
- [ ] 1.2 Link `Shared/` folder to the macOS target (same `PBXFileSystemSynchronizedRootGroup` pattern as iOS/watchOS)
- [ ] 1.3 Enable iCloud capability with "iCloud Documents" on macOS target (also verify iOS target has it)

## 2. macOS OAuth Client

- [ ] 2.1 Create `ClaudeTracker macOS/MacOSAPIClient.swift` — OAuth PKCE flow using `NSWorkspace.shared.open()` for browser, `code#state` paste-code parsing, token exchange via POST to `https://platform.claude.com/v1/oauth/token`
- [ ] 2.2 Implement `CredentialStore.swift` — read/write `~/.config/claude-tracker/credentials.json` with `0600` file permissions, `0700` directory permissions. Store `accessToken`, `refreshToken`, `expiresAt`, `scopes`
- [ ] 2.3 Implement auto-restore on launch — check `credentials.json` for valid (non-expired) token, refresh if expired, skip sign-in UI if valid
- [ ] 2.4 Implement token refresh on 401 — force-refresh once and retry, delete credentials on `invalid_grant`
- [ ] 2.5 Implement sign-out — delete `credentials.json`, stop polling, return to sign-in UI

## 3. macOS Usage Poller + iCloud Writer

- [ ] 3.1 Create `ClaudeTracker macOS/UsagePoller.swift` — poll `GET /api/oauth/usage` every 15 minutes with `Authorization: Bearer` and `anthropic-beta: oauth-2025-04-20` headers
- [ ] 3.2 Map API response to `UsageState` — divide utilization by 100, parse ISO 8601 dates, set `isMocked = false`
- [ ] 3.3 Implement reset timestamp reconciliation — preserve previous `resetAt5h`/`resetAt7d` when API returns null, discard on utilization drop
- [ ] 3.4 Implement exponential backoff on 429 — use `Retry-After` header, cap at 3600s, resume 15min on success
- [ ] 3.5 Write `UsageState` as JSON to `~/Library/Mobile Documents/com~apple~CloudDocs/ClaudeTracker/usage.json` — create directory if missing
- [ ] 3.6 Fire immediate poll on successful authentication

## 4. macOS Menu Bar UI

- [ ] 4.1 Create `ClaudeTracker macOS/ClaudeTrackerMacApp.swift` — `@main` App with `MenuBarExtra` (system image icon, no Dock icon)
- [ ] 4.2 Create sign-in view — "Sign in with Claude Code" button, TextField for paste-code, Submit/Cancel buttons
- [ ] 4.3 Create authenticated view — show account email (from `~/.claude/.claude.json` `oauthAccount.emailAddress`), sign-out button, last poll timestamp
- [ ] 4.4 Read Claude Code profile from `~/.claude/.claude.json` for display name/email (display only, not for auth)

## 5. iOS iCloud Reader (replace direct API polling)

- [ ] 5.1 Create `ClaudeTracker/iCloudUsageReader.swift` — `NSMetadataQuery` watching `ClaudeTracker/usage.json` in iCloud Drive, decode `UsageState`, relay to watch via `WatchConnectivity`
- [ ] 5.2 Handle file not-yet-downloaded — call `startDownloadingUbiquitousItem(at:)`, wait for next update notification
- [ ] 5.3 Restart `NSMetadataQuery` on `applicationDidBecomeActive` to catch changes from background
- [ ] 5.4 Update iOS `ContentView.swift` — replace sign-in screen with "Connect via Mac app" status, show "Syncing from Mac" when `usage.json` is detected, show staleness indicator if data > 30min old

## 6. Documentation Updates

- [ ] 6.1 Update `CLAUDE.md` — add macOS target to targets table, document new data flow
- [ ] 6.2 Update `docs/FUTURE_PLAN.md` — reflect macOS-first auth architecture in Phase 1

## 7. Verification

- [ ] 7.1 Build macOS target — confirm no compile errors
- [ ] 7.2 Sign in via browser OAuth on macOS — verify `credentials.json` created with correct permissions
- [ ] 7.3 Verify poll fires and `usage.json` appears in iCloud Drive
- [ ] 7.4 Verify iOS app detects `usage.json` via `NSMetadataQuery` and relays to watch
- [ ] 7.5 Verify sign-out deletes credentials and stops polling
