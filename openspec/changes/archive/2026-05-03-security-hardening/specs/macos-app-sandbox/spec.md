## ADDED Requirements

### Requirement: macOS App Sandbox should be enabled for App Store distribution

The macOS target SHALL declare `com.apple.security.app-sandbox: true` in `Tempo macOS/Tempo macOS.entitlements` for App Store distribution builds. For direct (non-App Store) distribution, sandbox remains optional but recommended. The code already handles both sandboxed and non-sandboxed modes via `isSandboxed` checks in `ClaudeLocalDBReader.swift`, so no runtime code changes are needed.

#### Scenario: App Store builds are sandboxed

- **WHEN** building with an App Store provisioning profile
- **THEN** `com.apple.security.app-sandbox` is `true` and the runtime sandbox is enforced

#### Scenario: Direct-distribution builds may remain unsandboxed

- **WHEN** building with a Developer ID provisioning profile
- **THEN** `com.apple.security.app-sandbox` may be omitted, but sandbox-enabling is recommended for defense-in-depth

#### Scenario: Network entitlement present when sandboxed

- **WHEN** App Sandbox is enabled
- **THEN** `com.apple.security.network.client` is declared to allow outbound HTTPS to Anthropic API endpoints and `status.claude.com`

#### Scenario: No new entitlements beyond network

- **WHEN** App Sandbox is enabled
- **THEN** no entitlements beyond `com.apple.security.app-sandbox` and `com.apple.security.network.client` are added. The existing bookmark and iCloud entitlements are sufficient.
