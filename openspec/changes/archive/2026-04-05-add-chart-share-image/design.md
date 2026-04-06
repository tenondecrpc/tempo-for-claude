## Context

`StatsDetailView` already renders the usage chart, activity heatmap, and insight cards, with a time-range menu (`5 Hours`, `24 Hours`, etc.) and CSV export action. Users now want a direct share action next to the time-range control that produces a polished image of the current chart state instead of a raw CSV file.

This change is macOS-specific and should align with the existing dark Claude theme already used in the stats window.

## Goals / Non-Goals

**Goals:**
- Add a share icon button adjacent to the chart time-range menu.
- Generate a PNG image that reflects the currently selected time range and visible data state.
- Present native macOS sharing options from the share button.
- Keep chart-share rendering deterministic and reusable (not an ad-hoc window screenshot).

**Non-Goals:**
- Replacing or removing existing CSV export.
- Building a full report designer/custom template system.
- Adding backend upload/sync for exported images.

## Decisions

### 1. Placement and interaction: icon button in chart header
Place `square.and.arrow.up` in the chart-section header, immediately after the time-range menu, matching the requested location near the filter.

Alternative considered:
- Keep share action at bottom near legend/CSV. Rejected because it is farther from the time-range control and does not match the requested UX.

### 2. Export source: dedicated share-card view, not raw screenshot
Create a dedicated SwiftUI export card (e.g., `StatsShareCardView`) that reuses filtered snapshot data and key summary values. The card will intentionally match the visual layout users expect (chart + activity/insights summary + footer branding/date), independent of window size.

Alternative considered:
- Capture an on-screen screenshot of the live window. Rejected because results vary with window size/scroll position and include non-essential UI.

### 3. Image generation: `ImageRenderer` to PNG
Use SwiftUI `ImageRenderer` to render the export card into `NSImage`, then encode PNG via `NSBitmapImageRep`.

Alternative considered:
- Manual Core Graphics drawing. Rejected due to higher maintenance cost and poorer reuse of existing SwiftUI styling.

### 4. Share sheet presentation: `NSSharingServicePicker`
Use AppKit native sharing (`NSSharingServicePicker`) with the generated image file URL (or image object), anchored to the share button.

Alternative considered:
- UIKit-style `UIActivityViewController`. Rejected because this target is macOS (`AppKit`).

### 5. Export file strategy: temporary PNG with stable naming
Write the rendered PNG to a temporary file such as `claude-usage-stats-<unix>.png`, then provide that file to sharing services for better interoperability with AirDrop/Messages/Files.

Alternative considered:
- Share in-memory image only. Rejected because some share targets behave better with file-backed items and preserved filename.

## Risks / Trade-offs

- **[Visual drift between on-screen chart and exported card]** -> Build export card from the same filtered data and color tokens used in `StatsDetailView`.
- **[Share fails when there is no chart data]** -> Disable share action or show a no-data message and avoid presenting picker.
- **[Large rendering cost on older machines]** -> Keep export card dimensions bounded and avoid rendering hidden/unused sections.
- **[AppKit/SwiftUI bridge complexity for picker anchor]** -> Isolate share presentation in a small helper (`StatsSharePresenter`) to keep `StatsDetailView` maintainable.

## Migration Plan

1. Add share action UI and presenter wiring in `StatsDetailView`.
2. Add export card renderer and PNG encoder utilities.
3. Validate flows manually: no data, normal data, custom date range, and multiple share targets.
4. Keep CSV export untouched as a fallback path.

## Open Questions

- Should the exported card include all lower sections (heatmap + all insight cards) or only a compact subset tuned for sharing?
- Should app branding/footer text be fixed (`Usage For Claude`) or configurable for future white-labeling?
