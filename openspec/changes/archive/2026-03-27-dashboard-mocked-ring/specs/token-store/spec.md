## ADDED Requirements

### Requirement: TokenStore is an Observable MainActor class
`TokenStore` SHALL be declared `@Observable @MainActor final class`. It SHALL NOT use `ObservableObject` or `@Published`. It SHALL NOT use `@AppStorage` for stored properties.

#### Scenario: Instantiation
- **WHEN** `TokenStore()` is called
- **THEN** `usageState` is initialized to `UsageState.mock` and `sessions` is an empty array

### Requirement: UsageState struct holds utilization data
`UsageState` SHALL be a `Codable` struct with fields: `utilization5h: Double`, `utilization7d: Double`, `resetAt5h: Date`, `resetAt7d: Date`, `isMocked: Bool`.

#### Scenario: All fields accessible
- **WHEN** a `UsageState` instance is created
- **THEN** all five fields are accessible and correctly typed

### Requirement: UsageState.mock provides fresh dates on each access
`UsageState.mock` SHALL be a `static var` (not `let`) so `Date()` is evaluated at access time. It SHALL set `utilization5h` to 0.42, `utilization7d` to 0.18, `resetAt5h` to `Date() + 2h 13min`, `resetAt7d` to `Date() + 4 days`, and `isMocked` to `true`.

#### Scenario: Mock accessed twice
- **WHEN** `UsageState.mock` is accessed at two different times
- **THEN** the `resetAt5h` values differ (each is relative to access time, not a fixed instant)

### Requirement: pendingCompletion triggers completion sheet
`TokenStore` SHALL expose `var pendingCompletion: SessionData?`. Setting it to a non-nil value SHALL cause the dashboard to present `CompletionView`. Setting it to `nil` SHALL dismiss the sheet.

#### Scenario: Set then clear
- **WHEN** `pendingCompletion` is set to a `SessionData` and then set to `nil`
- **THEN** the completion sheet appears and then disappears

### Requirement: SessionData is a Codable Identifiable struct
`SessionData` SHALL be a `Codable, Identifiable` struct with: `sessionId: String`, `inputTokens: Int`, `outputTokens: Int`, `costUSD: Double`, `durationSeconds: Int`, `timestamp: Date`, `limitResetAt: Date?`, `isDoubleLimitActive: Bool`. `id` SHALL return `sessionId`.

#### Scenario: Identifiable conformance
- **WHEN** `SessionData` instances are used in a `List` or `.sheet(item:)`
- **THEN** each instance is uniquely identified by `sessionId`
