## Requirements

### Requirement: SessionInfo costUSD is always zero on subscription
The `costUSD` field SHALL be retained in `SessionInfo` but SHALL always be `0.0` for Claude Max subscription users. Claude Code does not expose per-session cost data via hooks or the local DB on subscription plans.

#### Scenario: Cost field present but zero
- **WHEN** a `SessionInfo` is created from Stop hook data
- **THEN** `costUSD` SHALL equal `0.0`

#### Scenario: Mock fixtures use zero cost
- **WHEN** `MockData.swift` provides sample `SessionInfo` values
- **THEN** `costUSD` SHALL be `0.0` in all fixtures
