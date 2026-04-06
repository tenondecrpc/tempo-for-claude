## ADDED Requirements

### Requirement: Chart header exposes share action near time filter
The stats detail chart header SHALL display a share icon button (`square.and.arrow.up`) adjacent to the time-range filter control so users can export the currently selected chart context.

#### Scenario: Share action appears in chart header
- **WHEN** the stats detail view is shown
- **THEN** the header row that contains the time-range filter also contains a share icon button positioned next to that filter

#### Scenario: Share action reflects data availability
- **WHEN** there are no snapshots available for the currently selected range
- **THEN** the share action is disabled or no-op guarded and does not attempt image generation

### Requirement: Export image represents the active chart state
When a user invokes chart sharing, the app SHALL generate a PNG image that reflects the active time-range selection and currently visible chart data (Session and Weekly series), using the app's dark theme styling.

#### Scenario: Range-specific export
- **WHEN** the selected range is `5 Hours`
- **THEN** the generated image includes the `5 Hours` context and only data points included in that active range

#### Scenario: Custom-range export
- **WHEN** the selected range is `Custom` with specific start/end dates
- **THEN** the generated image includes chart data limited to that selected custom date window

### Requirement: Export image includes a share-ready dashboard card
The generated PNG SHALL include a cohesive share card that contains at least the chart block and key summary context (activity/insight metrics and export date) so recipients can interpret the snapshot without opening the app.

#### Scenario: Share card contains chart and summary context
- **WHEN** an export is generated successfully
- **THEN** the resulting PNG contains the chart visualization plus textual summary context and a footer with app/date metadata

### Requirement: Native macOS share sheet is presented with generated PNG
After successful PNG generation, the app SHALL present native macOS sharing options using `NSSharingServicePicker` anchored to the share button and populated with the generated PNG file item.

#### Scenario: Share picker opens after image generation
- **WHEN** the user clicks the share icon and PNG export succeeds
- **THEN** a native sharing picker opens from the share button with the generated PNG available to share targets (e.g., AirDrop, Messages, Notes)

#### Scenario: Export failure is surfaced gracefully
- **WHEN** PNG generation or temporary file write fails
- **THEN** no share picker is shown and the user is informed with a non-crashing failure message
