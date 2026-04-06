## ADDED Requirements

### Requirement: Menu bar percentage text visibility follows user preference
The menu bar item SHALL respect the Show Percentage in Menu Bar preference for authenticated usage display.

#### Scenario: Percentage text is shown
- **WHEN** the user has Show Percentage in Menu Bar enabled and usage data is available
- **THEN** the menu bar item displays the numeric session percentage next to the icon

#### Scenario: Percentage text is hidden
- **WHEN** the user disables Show Percentage in Menu Bar
- **THEN** the menu bar item displays icon-only usage state and no percentage text

## MODIFIED Requirements

### Requirement: Authenticated state shows usage dashboard
When the user is authenticated and usage data is available, the popover SHALL display:
1. "Current Session" label with session utilization as a bold percentage and a coral progress bar, with a reset subtitle formatted according to time-format preference (`24h` or `12h`)
2. "Weekly Limit" label with weekly utilization as a bold percentage and a progress bar, with reset day/time subtitle formatted according to time-format preference
3. A status line showing burn-rate assessment ("On track" or "High burn") with rate in %/hr
4. Last-polled relative timestamp

#### Scenario: Session usage displayed in 24-hour format
- **WHEN** the poller reports `utilization5h = 0.49`, `resetAt5h` is 13 minutes from now, and 24-hour time is enabled
- **THEN** the popover shows "Current Session", "49%", a progress bar at 49%, and a subtitle like "Resets in 13 min (20:00)"

#### Scenario: Session usage displayed in 12-hour format
- **WHEN** the poller reports `utilization5h = 0.49`, `resetAt5h` is 13 minutes from now, and 24-hour time is disabled
- **THEN** the popover shows a subtitle like "Resets in 13 min (8:00 PM)"

#### Scenario: Weekly usage displayed
- **WHEN** the poller reports `utilization7d = 0.04` and `resetAt7d` is next Sunday at 15:00
- **THEN** the popover shows "Weekly Limit", "4%", a progress bar at 4%, and a weekly reset subtitle using the selected time format

#### Scenario: Last polled timestamp shown
- **WHEN** the last successful poll was 2 minutes ago
- **THEN** the popover shows "2 min ago" as the last-polled time

### Requirement: Promo indicator is shown only when double-limit promotion is active
When usage payload decoding indicates an active double-limit promotion, the authenticated popover SHALL show a `2x promo active` indicator above Current Session and aligned to the right.

#### Scenario: Promotion active
- **WHEN** `isDoubleLimitPromoActive` is `true` in the latest usage state
- **THEN** the popover shows `2x promo active` above Current Session, right-aligned

#### Scenario: Promotion inactive or unknown
- **WHEN** `isDoubleLimitPromoActive` is `false` or `nil`
- **THEN** the promo indicator is not shown

### Requirement: Authenticated popover has action menu items
Below the usage data, after a divider, the popover SHALL show:
- "Usage History" with a chart.line.uptrend icon that opens the stats detail window
- "Logout" with an arrow.right.square icon that triggers sign-out
- "Quit" text in coral at the bottom

Settings controls (Launch at Login, Show Percentage, 24-Hour Time, Service Status Monitoring, Sync History via iCloud) SHALL be available from the stats/history settings surface rather than inline in this action list.

#### Scenario: Usage history opens stats detail with settings access
- **WHEN** the user clicks "Usage History"
- **THEN** the stats detail window opens and provides access to the settings surface

#### Scenario: Logout clears auth and returns to sign-in state
- **WHEN** the user clicks "Logout"
- **THEN** credentials/session state are cleared and the popover switches to the not-signed-in state

#### Scenario: Quit terminates the app
- **WHEN** the user clicks "Quit"
- **THEN** the macOS app terminates
