## Why

Users can view usage trends but cannot quickly share the current chart with teammates or save an image snapshot. Adding one-tap chart sharing next to the time-range filter improves collaboration and makes the stats view more useful without requiring manual screenshots.

## What Changes

- Add a share icon button near the chart time-range filter in the stats detail header.
- Generate a branded export image from the current chart state (selected range, rendered chart, summary metrics).
- Present the native iOS share sheet (`UIActivityViewController`) so users can share or save the generated PNG.
- Keep export rendering scoped to the currently visible chart data to match what the user is analyzing.

## Capabilities

### New Capabilities
- `chart-image-sharing`: Export and share an image representation of the active chart view from the stats detail screen.

### Modified Capabilities
- None.

## Impact

- Affected code:
  - iOS stats detail screen UI (header actions near time-range selector)
  - Chart export renderer/compositor for PNG generation
  - Share-sheet presentation bridge in SwiftUI
- Affected systems/APIs:
  - Swift Charts or chart rendering pipeline already used in app
  - UIKit `UIActivityViewController` integration from SwiftUI
- No backend/API contract changes.
