## Why

The macOS menu bar app currently lacks several high-value controls that users expect from the settings shown in your reference UI (launch at login, menu bar percentage visibility, time-format control, service health visibility, and cross-Mac history sync). Adding these as first-class settings improves day-to-day usability, reduces UI noise for users who prefer minimal menu bar text, and keeps historical analytics consistent across multiple Macs.

## What Changes

- Add a dedicated settings surface in the macOS menu bar app with persistent toggles for:
  - Launch at Login
  - Show Percentage in Menu Bar
  - 24-Hour Time
  - Service Status Monitoring
  - Sync History via iCloud
- Implement real launch-at-login registration/unregistration using `SMAppService` with graceful fallback messaging when app location is unsupported.
- Make menu bar percentage text optional (icon-only mode when disabled) while keeping current usage icon behavior intact.
- Add configurable time formatting (12h/24h) for reset labels and related popover timestamps.
- Detect and surface Claude `2x promo active` state above Current Session when usage payload indicates double-limit promotion is active.
- Implement Claude service status polling and surface health state in the menu bar experience when monitoring is enabled.
- Add iCloud-backed usage-history synchronization so historical snapshots are shared across the user's Macs.

## Capabilities

### New Capabilities
- `macos-settings-preferences`: Preferences model, persistence, and settings UI controls for the macOS menu bar app.
- `service-status-monitoring`: Poll and display Claude service health status in the macOS menu bar app.
- `icloud-history-sync`: Synchronize persisted usage-history snapshots across Macs via iCloud.

### Modified Capabilities
- `macos-menu-bar-ui`: Add settings entry points/visibility behavior changes and integrate preference-driven menu bar presentation.

## Impact

- Affected code:
  - macOS menu bar UI (`AuthenticatedView`, header/actions, settings container)
  - menu bar icon rendering/presentation (`DynamicMenuBarIconView`)
  - date/time formatting paths used in usage/reset labels
  - usage-history persistence layer (`UsageHistory`)
  - app coordinator wiring for settings + service-status + history sync services
- Affected systems/APIs:
  - `ServiceManagement` (`SMAppService`) for launch-at-login
  - iCloud ubiquity container file storage for cross-Mac history sync
  - Claude status endpoint integration (read-only polling)
- No OAuth flow changes and no watchOS transport contract break is expected.
