## ADDED Requirements

### Requirement: AuthTrace logs must use `.private` privacy level

The `DevLog.trace("AuthTrace", ...)` log path SHALL emit messages with `privacy: .private` instead of `privacy: .public`. Non-auth categories (`"UsageTrace"`, etc.) may continue using `.public` for operational visibility.

#### Scenario: AuthTrace logs are private

- **WHEN** `DevLog.trace("AuthTrace", message)` is called
- **THEN** the log entry is emitted with `OSLogPrivacy.private` and SHALL NOT appear in Console.app for non-admin users, diagnostic reports, or unified log exports

#### Scenario: AuthTrace logs never contain raw tokens

- **WHEN** any `DevLog.trace("AuthTrace", ...)` call site is written or modified
- **THEN** the interpolated message SHALL NOT include `accessToken`, `refreshToken`, or any credential value (existing call sites already comply; this codifies the invariant)

#### Scenario: Non-auth categories are unchanged

- **WHEN** `DevLog.trace("UsageTrace", message)` or any category other than `"AuthTrace"` is called
- **THEN** the current `.public` behavior is preserved

#### Scenario: Audit existing AuthTrace call sites

- **WHEN** the privacy change ships
- **THEN** all `DevLog.trace("AuthTrace", ...)` call sites across the codebase are reviewed to confirm no raw tokens are interpolated. Current sites include: `MacOSAPIClient.swift` lines 176, 212, 333, 354, 424, 483, 496; `AnthropicAPIClient.swift` lines 102, 236, 249, 260; `UsagePoller.swift` line 244; `ClaudeCodeKeychainReader.swift` lines 117, 126. None embed raw tokens.
