## Requirements

### Requirement: Popover header with title and action icons
The menu bar popover SHALL display a header row containing "Usage for Claude" as a bold title on the left, and help (questionmark.circle) and chat (message) icon buttons on the right. A horizontal divider SHALL separate the header from the content below.

#### Scenario: Header displayed in all states
- **WHEN** the menu bar popover is opened
- **THEN** the header row with "Usage for Claude" title and icon buttons is visible at the top

### Requirement: Not-signed-in state shows lock and sign-in button
When the user is not authenticated, the popover SHALL display a centered blue lock icon (lock.fill), "Not Signed In" as a bold headline, a subtitle "Sign in to view your Claude Usage", and a full-width coral (#E07850) "Sign In" button. A "Quit" text button in red SHALL appear at the bottom below a divider.

#### Scenario: Unauthenticated popover appearance
- **WHEN** the popover opens and the user is not authenticated
- **THEN** the lock icon, "Not Signed In" headline, subtitle, coral "Sign In" button, and "Quit" link are displayed

#### Scenario: Sign In button opens Welcome window
- **WHEN** the user clicks the "Sign In" button
- **THEN** the Welcome window opens as a separate centered macOS window

### Requirement: Authenticated state shows usage dashboard
When the user is authenticated and usage data is available, the popover SHALL display:
1. "Current Session" label with session utilization as a bold percentage and a coral progress bar, with "Resets in X min (HH:MM)" subtitle
2. "Weekly Limit" label with weekly utilization as a bold percentage and a progress bar, with reset day/time subtitle
3. A status line showing burn-rate assessment ("On track" or "High burn") with rate in %/hr
4. Last-polled relative timestamp

#### Scenario: Session usage displayed
- **WHEN** the poller reports `utilization5h = 0.49` and `resetAt5h` is 13 minutes from now at 20:00
- **THEN** the popover shows "Current Session", "49%", a progress bar at 49%, and "Resets in 13 min (20:00)"

#### Scenario: Weekly usage displayed
- **WHEN** the poller reports `utilization7d = 0.04` and `resetAt7d` is next Sunday at 15:00
- **THEN** the popover shows "Weekly Limit", "4%", a progress bar at 4%, and "Resets Sun, 15:00"

#### Scenario: Last polled timestamp shown
- **WHEN** the last successful poll was 2 minutes ago
- **THEN** the popover shows "2 min ago" as the last-polled time

### Requirement: Authenticated popover has action menu items
Below the usage data, after a divider, the popover SHALL show:
- "Usage History" with a chart.line.uptrend icon (non-functional placeholder)
- "Launch at Login" with a power icon and a toggle switch (non-functional placeholder)
- "Logout" with an arrow.right.square icon that triggers sign-out
- "Quit" text in coral at the bottom

#### Scenario: Logout clears auth and returns to sign-in state
- **WHEN** the user clicks "Logout"
- **THEN** credentials are cleared and the popover switches to the not-signed-in state

#### Scenario: Quit terminates the app
- **WHEN** the user clicks "Quit"
- **THEN** the macOS app terminates

### Requirement: Logout stops session and blocks auto-restore
When the user clicks "Logout", the app SHALL:
1. Reset `authState.isAuthenticated` and `authState.isAwaitingCode` to `false`
2. Set `authState.requiresExplicitSignIn = true` to block automatic session restoration
3. Stop the usage poller
4. Transition the popover immediately to the not-signed-in state

Credentials on disk are NOT deleted — they can be reused on the next explicit sign-in. No confirmation dialog is required.

The `requiresExplicitSignIn` flag ensures that reopening the menu bar popover (which triggers `onLaunch`) does NOT auto-restore the session. Only an explicit user action ("Sign in with Claude Code") resets this flag and allows credential reuse.

#### Scenario: Poller stops on logout
- **WHEN** the user clicks "Logout"
- **THEN** the 15-minute usage polling timer is cancelled and no further API requests are made

#### Scenario: Popover switches to not-signed-in immediately
- **WHEN** the user clicks "Logout"
- **THEN** the popover transitions to the not-signed-in state (lock icon + "Sign In" button) without app restart

#### Scenario: Reopening menu bar after logout stays signed out
- **WHEN** the user clicks "Logout" and then reopens the menu bar popover
- **THEN** the popover shows "Not Signed In" — no auto-restore occurs even if credentials exist on disk

#### Scenario: Logging out while Welcome window is open
- **WHEN** the Welcome window is open and the user triggers logout from another path
- **THEN** the Welcome window remains open (no automatic close — user is already in the sign-in flow)

#### Scenario: Credentials reusable via explicit sign-in
- **WHEN** the user clicks "Sign in with Claude Code" after a logout
- **THEN** `requiresExplicitSignIn` is reset to `false`, the app checks stored credentials, and restores the session without opening the browser

### Requirement: Dark theme applied to popover
The popover content SHALL use a dark color scheme (`.preferredColorScheme(.dark)`) with ClaudeTheme colors for background, text, and accents.

#### Scenario: Popover uses dark appearance
- **WHEN** the popover opens regardless of system appearance setting
- **THEN** the popover renders with dark navy background and light text
