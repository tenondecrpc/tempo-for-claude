## Requirements

### Requirement: Service status monitoring polls Claude status endpoint when enabled
When Service Status Monitoring is enabled, the macOS app SHALL poll the configured Claude status endpoint and derive an app-level health state.

#### Scenario: Monitoring enabled starts polling
- **WHEN** the Service Status Monitoring toggle is enabled
- **THEN** the status monitor begins periodic status fetches and stores the latest derived health state

#### Scenario: Monitoring disabled stops polling
- **WHEN** the Service Status Monitoring toggle is disabled
- **THEN** the status monitor stops polling and no further status fetches are scheduled

### Requirement: Status indicator is exposed to menu bar experience
The app SHALL expose the derived service health state to the menu bar experience so users can see Claude service condition without opening external status pages.

#### Scenario: Operational status
- **WHEN** the endpoint reports an operational/none indicator
- **THEN** the app shows an operational state indicator in the menu bar experience

#### Scenario: Degraded or outage status
- **WHEN** the endpoint reports degraded performance, partial outage, or major outage indicators
- **THEN** the app shows a non-operational warning state in the menu bar experience

### Requirement: Monitoring failures degrade gracefully
Status monitoring failures SHALL NOT block usage polling, history tracking, or app interactivity.

#### Scenario: Status endpoint unavailable
- **WHEN** status fetch fails due to network/server/parsing issues
- **THEN** the app maps state to `unavailable` or `stale`, keeps core usage features running, and retries on the next interval

#### Scenario: Endpoint recovers after failure
- **WHEN** a subsequent status fetch succeeds after one or more failures
- **THEN** the app replaces the stale/unavailable state with the latest valid health state
