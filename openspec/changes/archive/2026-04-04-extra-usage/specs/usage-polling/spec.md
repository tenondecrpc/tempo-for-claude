## MODIFIED Requirements

### Requirement: API response decoding
The `UsagePoller.fetchUsage()` method SHALL decode the full API response including the optional `extra_usage` field. The internal `Response` struct SHALL include:
- `five_hour: Window`
- `seven_day: Window`
- `extra_usage: ExtraUsage?`

The decoded `ExtraUsage` SHALL be passed through to the returned `UsageState`.

#### Scenario: API response with extra_usage present
- **WHEN** the API returns a response containing `"extra_usage": {"is_enabled": true, "monthly_limit": 2000, "used_credits": 530, "utilization": 26.5}`
- **THEN** `fetchUsage()` returns a `UsageState` with `extraUsage` populated

#### Scenario: API response without extra_usage
- **WHEN** the API returns a response without the `extra_usage` field
- **THEN** `fetchUsage()` returns a `UsageState` with `extraUsage = nil`
