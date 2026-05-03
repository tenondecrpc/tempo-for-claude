## Purpose

Define OAuth callback state validation requirements.

## Requirements

### Requirement: OAuth state parameter must always be validated
The `submitOAuthCode` method (macOS `MacOSAPIClient.swift` and iOS `AnthropicAPIClient.swift`) SHALL validate the `state` parameter unconditionally. If the incoming authorization code does not include a valid `state` value, the exchange SHALL be rejected.

#### Scenario: State present and matches
- **WHEN** the callback code contains a `#` fragment AND `parts[1] == pendingOAuthState`
- **THEN** the code exchange proceeds (unchanged behavior)

#### Scenario: State absent from callback
- **WHEN** the callback code has no `#` fragment (`parts.count == 1`)
- **THEN** the code exchange SHALL fail with an appropriate error and `clearPendingOAuth()` SHALL be called

#### Scenario: State present but mismatched
- **WHEN** the callback code has a `#` fragment AND `parts[1] != pendingOAuthState`
- **THEN** the code exchange SHALL fail (unchanged behavior - already guarded)

#### Scenario: macOS client
- **WHEN** `MacOSAPIClient.submitOAuthCode(_:)` processes a code
- **THEN** the method emits a `guard` that requires `parts.count > 1` before proceeding past code extraction, and if `pendingOAuthState` is non-nil, validates the fragment matches

#### Scenario: iOS client
- **WHEN** `AnthropicAPIClient.submitOAuthCode(_:)` processes a code
- **THEN** the method applies the same unconditional validation as macOS
