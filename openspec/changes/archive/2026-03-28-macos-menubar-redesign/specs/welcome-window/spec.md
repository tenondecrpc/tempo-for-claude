## ADDED Requirements

### Requirement: Welcome window opens from menu bar Sign In
A separate macOS window (SwiftUI `Window` scene, id "welcome") SHALL open when the user clicks "Sign In" in the menu bar popover. The window SHALL be centered on screen, approximately 600×500pt, with a dark background.

#### Scenario: Window opens on Sign In click
- **WHEN** the user clicks "Sign In" in the not-signed-in popover
- **THEN** a centered "Welcome to Usage for Claude" window appears

#### Scenario: Window is a separate scene from MenuBarExtra
- **WHEN** the Welcome window is open
- **THEN** it exists as an independent window that can be focused and closed independently of the menu bar popover

### Requirement: Welcome window shows onboarding content
The window SHALL display:
1. Large bold title: "Welcome to Usage for Claude"
2. Subtitle: "Track your Claude Usage for Claude right from your menu bar or widget."
3. A preview/mockup area showing the authenticated menu bar state
4. Two action buttons at the bottom, side by side

#### Scenario: Onboarding content visible
- **WHEN** the Welcome window is displayed
- **THEN** the title, subtitle, preview area, and sign-in buttons are all visible

### Requirement: Sign in with Claude Code button triggers OAuth
The "Sign in with Claude Code" button SHALL have a coral (#E07850) background with white text and a terminal icon (terminal.fill or similar). Clicking it SHALL initiate the existing OAuth PKCE flow.

#### Scenario: OAuth flow initiated
- **WHEN** the user clicks "Sign in with Claude Code"
- **THEN** the OAuth PKCE authorization URL is opened in the default browser

### Requirement: Sign in with Email button is a disabled placeholder
The "Sign in with Email" button SHALL have a dark/gray background with white text and an envelope icon. It SHALL be visually distinct as non-functional (reduced opacity or "Coming Soon" label).

#### Scenario: Email button is not interactive
- **WHEN** the user clicks "Sign in with Email"
- **THEN** nothing happens (button is disabled or shows a "Coming Soon" message)

### Requirement: Welcome window auto-closes on authentication
The Welcome window SHALL close automatically when the user completes authentication (authState transitions to authenticated).

#### Scenario: Window closes after successful sign-in
- **WHEN** the OAuth flow completes and the user becomes authenticated
- **THEN** the Welcome window dismisses automatically

### Requirement: Welcome window uses dark theme
The window SHALL use `.preferredColorScheme(.dark)` and ClaudeTheme colors consistent with the menu bar popover.

#### Scenario: Dark appearance regardless of system setting
- **WHEN** the Welcome window opens on a system set to light mode
- **THEN** the window renders with dark background and light text
