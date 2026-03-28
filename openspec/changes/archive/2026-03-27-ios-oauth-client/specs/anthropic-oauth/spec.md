## ADDED Requirements

### Requirement: PKCE sign-in via ASWebAuthenticationSession
The app SHALL authenticate users via OAuth PKCE using `ASWebAuthenticationSession`. The authorization URL SHALL be constructed with the confirmed parameters from `docs/APIS.md`: client ID `9d1c250a-e61b-44d9-88ed-5944d1962f5e`, redirect URI `https://platform.claude.com/oauth/code/callback`, scopes `user:profile user:inference`, method `S256`.

#### Scenario: User initiates sign-in
- **WHEN** the user taps "Sign in with Claude" on the iOS app
- **THEN** `ASWebAuthenticationSession` opens the Anthropic authorization URL in the system browser

#### Scenario: Authorization code received
- **WHEN** the browser redirects to the callback URL with a `<code>#<state>` string
- **THEN** the app extracts the code (before `#`) and state (after `#`) and exchanges them for tokens

#### Scenario: Token exchange succeeds
- **WHEN** the token exchange POST to `https://platform.claude.com/v1/oauth/token` returns `access_token` and `refresh_token`
- **THEN** both tokens are stored in the iOS Keychain and the app transitions to authenticated state

### Requirement: Tokens stored in iOS Keychain
Access and refresh tokens SHALL be stored using `SecItem` APIs with `kSecAttrAccessibleAfterFirstUnlock`. Tokens SHALL never be stored in `UserDefaults`, `NSUbiquitousKeyValueStore`, or any plist.

#### Scenario: Tokens written after sign-in
- **WHEN** OAuth token exchange succeeds
- **THEN** `access_token` and `refresh_token` are written to Keychain via `SecItemAdd` / `SecItemUpdate`

#### Scenario: Tokens survive app restart
- **WHEN** the app is killed and relaunched
- **THEN** tokens are read from Keychain and the user remains authenticated without re-signing-in

### Requirement: Access token auto-refreshed before expiry
The app SHALL proactively refresh the access token using the refresh token before each API call if the token is expired or within 5 minutes of expiry. On `401` response, the app SHALL force-refresh once and retry the request. On permanent refresh failure (`invalid_grant` or repeated 401), the app SHALL clear stored tokens and return to unauthenticated state.

#### Scenario: Proactive refresh before poll
- **WHEN** the poller is about to call `/api/oauth/usage` and the access token expires within 5 minutes
- **THEN** the token is refreshed first, then the API call proceeds with the new token

#### Scenario: 401 forces refresh and retry
- **WHEN** an API call returns HTTP 401
- **THEN** the client refreshes the token and replays the request exactly once

#### Scenario: Refresh fails permanently
- **WHEN** the refresh token endpoint returns `invalid_grant` or repeated 401
- **THEN** Keychain tokens are deleted and the app shows the sign-in screen

### Requirement: Sign-out clears all stored credentials
The app SHALL provide a sign-out action that deletes both tokens from Keychain and returns the app to unauthenticated state, stopping all polling.

#### Scenario: User signs out
- **WHEN** the user triggers sign-out
- **THEN** both `access_token` and `refresh_token` are removed from Keychain and polling stops
