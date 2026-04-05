## 1. State

- [x] 1.1 Add `@State private var customStart: Date` (default: yesterday) and `@State private var customEnd: Date` (default: today)
- [x] 1.2 Add `@State private var previousTimeRange: TimeRange` to remember the range before switching to `.custom`

## 2. Menu wiring

- [x] 2.1 Update the `Menu` `Button` action to save `timeRange` to `previousTimeRange` before assigning `.custom`

## 3. Inline date picker UI

- [x] 3.1 Below the `HStack` menu row, conditionally show a date picker row when `timeRange == .custom`
- [x] 3.2 Row contains: start `DatePicker` (`.compact`, `.dateOnly`) → "to" `Text` → end `DatePicker` (`.compact`, `.dateOnly`) → `Button` with `xmark` SF symbol
- [x] 3.3 X button action: set `timeRange = previousTimeRange`
- [x] 3.4 Add `onChange(of: customStart)` to clamp `customEnd = max(customEnd, customStart)`

## 4. Data filtering

- [x] 4.1 Update `filteredSnapshots()` `.custom` case to filter by `customStart...customEnd`
- [x] 4.2 Update `dateDomain()` `.custom` case to return `customStart...customEnd`

## 5. X-axis stride for custom range

- [x] 5.1 In `.chartXAxis`, add a branch for `timeRange == .custom` that computes span = `customEnd - customStart` and picks stride: ≤24h → 3h, ≤7d → 1d, otherwise `.automatic`
