### Requirement: WCSession activated at iOS app launch
`WatchRelayManager` SHALL activate `WCSession.default` at iOS app launch by setting itself as delegate and calling `activate()`. The delegate MUST be set before `activate()` is called.

#### Scenario: Session activated on launch
- **WHEN** the iOS app finishes launching
- **THEN** `WCSession.default.delegate` is set and `activate()` is called before any transfer is attempted

### Requirement: UsageState delivered via transferUserInfo
`WatchRelayManager` SHALL send `UsageState` to the watch using `WCSession.default.transferUserInfo(_:)` with a `"type": "UsageState"` discriminator key. The payload SHALL encode all `UsageState` fields as primitive values (`Double`, `TimeInterval`, `Bool`).

#### Scenario: UsageState sent after successful poll
- **WHEN** `UsageStatePoller` produces a new `UsageState`
- **THEN** `WatchRelayManager` calls `transferUserInfo` with the encoded payload

#### Scenario: Type discriminator present
- **WHEN** a `UsageState` payload is sent
- **THEN** the dictionary contains `"type": "UsageState"`

### Requirement: Stale UsageState transfers cancelled before each send
Before sending a new `UsageState`, `WatchRelayManager` SHALL cancel all outstanding `transferUserInfo` transfers whose `"type"` is `"UsageState"`. This prevents a burst of stale polling snapshots from being delivered when the watch reconnects after being offline.

#### Scenario: Stale transfers pruned
- **WHEN** a new `UsageState` is ready to send and there are pending `UsageState` transfers in the queue
- **THEN** those pending transfers are cancelled before the new one is enqueued

#### Scenario: SessionInfo transfers never cancelled
- **WHEN** pruning stale `UsageState` transfers
- **THEN** any transfers with `"type": "SessionInfo"` are left untouched
