## MODIFIED Requirements

### Requirement: Usage polled every 15 minutes on macOS
The macOS app SHALL poll `GET https://api.anthropic.com/api/oauth/usage` at a 15-minute interval while the user is authenticated. The request SHALL include `Authorization: Bearer <access_token>` and `anthropic-beta: oauth-2025-04-20` headers. A poll SHALL fire immediately on successful authentication.

The poller SHALL expose the latest `UsageState` as an observable property on `MacAppCoordinator` (or the poller itself) so that SwiftUI views can reactively display current usage data.

#### Scenario: Poll fires on schedule
- **WHEN** 15 minutes elapse since the last successful poll
- **THEN** the app issues a new `GET /api/oauth/usage` request

#### Scenario: Poll fires immediately after sign-in
- **WHEN** OAuth authentication succeeds
- **THEN** a poll is issued immediately without waiting for the 15-minute interval

#### Scenario: Latest usage state is observable by views
- **WHEN** a poll returns HTTP 200 with valid usage data
- **THEN** the `latestUsage: UsageState?` property is updated and any observing SwiftUI views re-render
