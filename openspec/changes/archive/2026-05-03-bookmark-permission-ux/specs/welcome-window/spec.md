## MODIFIED Requirements

### Requirement: Welcome window opens from menu bar Sign In
A separate macOS window (SwiftUI `Window` scene, id "welcome") SHALL open when the user clicks "Sign In" in the menu bar popover. Clicking Sign In SHALL also close the menu bar popover synchronously before opening the window. The window SHALL be centered on screen, approximately 600x500pt, with a dark background using `TempoTheme.background`.

#### Scenario: Window opens on Sign In click
- **WHEN** the user clicks "Sign In" in the not-signed-in popover
- **THEN** the popover closes and a centered "Welcome to Tempo for Claude" window appears

#### Scenario: Window is a separate scene from MenuBarExtra
- **WHEN** the Welcome window is open
- **THEN** it exists as an independent window that can be focused and closed independently of the menu bar popover

#### Scenario: Welcome does not request folder access on appear
- **WHEN** the Welcome window appears
- **THEN** it does not call `requestHomeDirectoryAccess()` or `requestFolderAccess()`

#### Scenario: Missing home bookmark does not block welcome
- **WHEN** the Welcome window appears and no `homeFolder` bookmark exists
- **THEN** the welcome content remains usable and no folder picker is shown automatically
