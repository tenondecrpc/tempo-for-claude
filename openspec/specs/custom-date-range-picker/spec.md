## ADDED Requirements

### Requirement: Custom date range picker shown in chart header
When `timeRange == .custom`, the chart header SHALL replace the preset label with an inline row showing a start `DatePicker`, a "to" label, an end `DatePicker`, and an X dismiss button.

#### Scenario: Picker appears on custom selection
- **WHEN** user selects "Custom" from the time range menu
- **THEN** the chart header shows two `.compact` DatePickers (start and end) and an X button

#### Scenario: Picker is hidden for preset ranges
- **WHEN** `timeRange` is any preset (5h, 24h, 7d, 30d, 90d)
- **THEN** no date pickers are visible; only the menu label is shown

### Requirement: Custom range filters chart data
`filteredSnapshots()` and `dateDomain()` SHALL use `customStart` and `customEnd` when `timeRange == .custom`.

#### Scenario: Snapshots filtered to custom range
- **WHEN** `timeRange == .custom` and dates are set
- **THEN** only snapshots with `date >= customStart` and `date <= customEnd` are charted

#### Scenario: Domain matches custom range
- **WHEN** `timeRange == .custom`
- **THEN** `dateDomain()` returns `customStart...customEnd`

### Requirement: End date clamped to be >= start date
The system SHALL ensure `customEnd` is never earlier than `customStart`.

#### Scenario: User sets end before start
- **WHEN** user selects an end date earlier than `customStart`
- **THEN** `customEnd` is automatically set to `customStart`

### Requirement: X button restores previous preset
The system SHALL restore the previous non-custom `TimeRange` when the user taps the X button.

#### Scenario: Dismiss returns to last preset
- **WHEN** user taps the X button in the custom picker row
- **THEN** `timeRange` is set back to the preset that was active before "Custom" was selected

### Requirement: X-axis stride adapts to custom span
The chart x-axis stride SHALL reflect the selected custom date range.

#### Scenario: Short custom range (≤24h)
- **WHEN** custom span is 24 hours or less
- **THEN** x-axis marks are every 3 hours

#### Scenario: Medium custom range (≤7d)
- **WHEN** custom span is between 1 and 7 days
- **THEN** x-axis marks are every 1 day

#### Scenario: Long custom range (>7d)
- **WHEN** custom span exceeds 7 days
- **THEN** x-axis uses `.automatic` stride
