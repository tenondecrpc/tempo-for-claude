## Purpose

Define the macOS welcome window and sign-in entry behavior.

## Requirements

### Requirement: Welcome window opens from menu bar Sign In
A separate macOS window (SwiftUI `Window` scene, id "welcome") SHALL open when the user clicks "Sign In" in the menu bar popover. Clicking Sign In SHALL also close the menu bar popover synchronously before opening the window. The window SHALL be centered on screen, approximately 600×500pt, with a dark background using `TempoTheme.background`.

#### Scenario: Window opens on Sign In click
- **WHEN** the user clicks "Sign In" in the not-signed-in popover
- **THEN** the popover closes and a centered "Welcome to Tempo for Claude" window appears

#### Scenario: Window is a separate scene from MenuBarExtra
- **WHEN** the Welcome window is open
- **THEN** it exists as an independent window that can be focused and closed independently of the menu bar popover

### Requirement: Welcome window shows onboarding content
The window SHALL display:
1. Large bold title: "Welcome to Tempo for Claude"
2. Subtitle: "Track your Claude usage right from your menu bar."
3. A preview area showing a ring gauge mockup (concentric rings with hardcoded ~49% session, ~4% weekly values) instead of a flat progress bar mockup
4. Two action buttons at the bottom, side by side

#### Scenario: Onboarding content visible
- **WHEN** the Welcome window is displayed
- **THEN** the title "Welcome to Tempo for Claude", subtitle, ring gauge preview, and sign-in buttons are all visible

#### Scenario: Ring preview shows approximate usage
- **WHEN** the Welcome window is displayed
- **THEN** the preview shows hardcoded concentric rings at ~49% session (inner, violet) and ~4% weekly (outer, blue)

### Requirement: Sign in with Claude Code restores safe credentials first
The "Sign in with Claude Code" button SHALL first attempt `tryRestoreSession()`. Restore SHALL prefer Tempo OAuth credentials from Keychain, refresh only Tempo OAuth credentials if needed, and may use a fresh Claude Code CLI access token as a read-only fallback. If no valid Tempo OAuth credentials and no fresh CLI access token exist, the button SHALL initiate the OAuth PKCE browser flow. While checking, the button SHALL show a spinner for a minimum of 2 seconds before proceeding.

#### Scenario: Valid Tempo OAuth credentials restore session without browser
- **WHEN** the user clicks "Sign in with Claude Code" and valid Tempo OAuth credentials exist in Keychain
- **THEN** a spinner is shown for at least 2 seconds, the session is restored as `webOAuth`, and the window closes

#### Scenario: Fresh CLI access token restores session without browser
- **WHEN** the user clicks "Sign in with Claude Code", Tempo OAuth credentials are unavailable, and Claude Code has a fresh CLI access token
- **THEN** a spinner is shown for at least 2 seconds, the session is restored as `cliSession`, and the window closes

#### Scenario: Expired CLI token does not restore session
- **WHEN** the user clicks "Sign in with Claude Code" and the only available Claude Code CLI token is expired
- **THEN** Tempo does not refresh Claude Code credentials and proceeds to the OAuth PKCE browser flow

#### Scenario: No credentials triggers OAuth flow
- **WHEN** the user clicks "Sign in with Claude Code" and no valid Tempo OAuth credentials or fresh CLI access token exist
- **THEN** after the spinner, the OAuth PKCE authorization URL is opened in the default browser

### Requirement: Sign in with Email button is a disabled placeholder
The "Sign in with Email" button SHALL have a `TempoTheme.surface` background with `TempoTheme.textPrimary` text and an envelope icon. It SHALL be visually distinct as non-functional (reduced opacity or "Coming Soon" label).

#### Scenario: Email button is not interactive
- **WHEN** the user clicks "Sign in with Email"
- **THEN** nothing happens (button is disabled or shows a "Coming Soon" message)

### Requirement: Welcome window auto-closes on authentication
The Welcome window SHALL close automatically when the user completes authentication (authState transitions to authenticated), but only after the minimum spinner duration has elapsed.

#### Scenario: Window closes after successful sign-in
- **WHEN** the OAuth flow completes and the user becomes authenticated
- **THEN** the Welcome window dismisses automatically

#### Scenario: Spinner does not block close on OAuth path
- **WHEN** the user completes OAuth in the browser (isAwaitingCode path)
- **THEN** the window closes immediately on authentication without waiting for a spinner

### Requirement: Welcome window uses dark theme with TempoTheme
The window SHALL use `.preferredColorScheme(.dark)` and `TempoTheme` colors consistent with the menu bar popover. `ClaudeTheme` references SHALL be replaced with `TempoTheme` equivalents.

#### Scenario: Dark appearance regardless of system setting
- **WHEN** the Welcome window opens on a system set to light mode
- **THEN** the window renders with dark charcoal background (#19191C) and light text
