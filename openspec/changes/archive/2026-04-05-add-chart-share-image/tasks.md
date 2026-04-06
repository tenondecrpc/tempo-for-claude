## 1. Chart Header Share Control

- [x] 1.1 Add a `square.and.arrow.up` share button in the `StatsDetailView` chart header next to the time-range menu.
- [x] 1.2 Wire button enable/disable behavior so share is unavailable when there is no data for the active range.
- [x] 1.3 Keep existing time-range and CSV behaviors unchanged while introducing the new share action.

## 2. Share Image Rendering

- [x] 2.1 Create a reusable export card view for sharing that includes current chart context and summary metadata.
- [x] 2.2 Implement PNG rendering with `ImageRenderer` using the active filtered snapshots and selected time range.
- [x] 2.3 Add temporary file writing with deterministic filename format (`claude-usage-stats-<timestamp>.png`).

## 3. Native Sharing Integration

- [x] 3.1 Present `NSSharingServicePicker` anchored from the share button after successful PNG generation.
- [x] 3.2 Handle export/render/write failures gracefully and avoid presenting share UI on failure.
- [x] 3.3 Verify end-to-end flow manually for: 5 Hours range, Custom range, no-data state, and at least one share target (e.g., AirDrop or Messages).
