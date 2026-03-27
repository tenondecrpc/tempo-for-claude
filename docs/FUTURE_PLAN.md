# Claude Code Token Tracker — Apple Watch App

**Architecture**: Claude Code Stop hook → iCloud Drive JSON file → iOS companion monitors file → WatchConnectivity → watchOS haptic + alert screen.

---

## Execution Order (Recommended)

```
CORE PIPELINE:          0 → 1 → 2 → 3
HIGH VALUE FEATURES:    4 → 5 → 6
REAL DATA & QA:         7 → 8
```

**Phases in order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8**

---

## Phase 0: Documentation Discovery
**TIER 1 — Prerequisite for everything**

**Goal**: Verify exact APIs before writing any code. Deploy research subagents on:

1. **Claude Code hooks** — read `~/.claude/settings.json` schema; identify what env vars the Stop hook receives (tokens, cost, session ID, limit window, reset timestamp, context usage, etc.)
   - Source: `WebFetch` the Claude Code hooks docs
   - Need: exact env var names for `input_tokens`, `output_tokens`, `cost_usd`, `limit_reset_at`, and **context window stats**

2. **WatchConnectivity** — `WCSession`, `sendMessage(_:replyHandler:)` vs `transferUserInfo(_:)`, activation states, background delivery
   - Source: Apple Developer docs + any existing patterns in `.agents/skills/swiftui-expert-skill/references/`

3. **NSMetadataQuery for iCloud** — how to watch for file changes in `~/Library/Mobile Documents/com~apple~CloudDocs/`
   - Pattern: `NSMetadataQuery` with `NSMetadataQueryUbiquitousDocumentsScope`

4. **WKHapticType (watchOS)** — exact enum cases: `.notification`, `.directionUp`, `.success`, etc.
   - Also: `WKInterfaceDevice.current().play(_:)`

5. **Local notifications on watchOS** — `UNUserNotificationCenter` for the limit-reset alarm

**Output**: "Allowed APIs" doc saved as `/docs/APIS.md`

---

## Phase 1: Data Model + Claude Code Stop Hook
**TIER 1 — The heart of the pipeline**

**What to implement:**

1. **`SessionData.swift`** (Shared) — Codable struct:
   ```swift
   struct SessionData: Codable, Identifiable {
       let sessionId: String
       let inputTokens: Int
       let outputTokens: Int
       let costUSD: Double
       let durationSeconds: Int
       let timestamp: Date
       let limitResetAt: Date?
       let isDoubleLimitActive: Bool

       var id: String { sessionId }
   }
   ```

2. **Stop hook shell script** at `~/.claude/hooks/stop-tracker.sh`:
   - Reads env vars provided by Claude Code — exact names confirmed in Phase 0
   - Writes JSON to `~/Library/Mobile Documents/com~apple~CloudDocs/ClaudeTracker/latest.json`
   - Creates the iCloud directory if it doesn't exist

3. **Register the hook** in `~/.claude/settings.json`:
   ```json
   { "hooks": { "Stop": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/stop-tracker.sh" }] }] } }
   ```

**Verification checklist:**
- Run `echo $CLAUDE_INPUT_TOKENS` inside a test hook to confirm var names
- Manually trigger hook: check `~/Library/Mobile Documents/com~apple~CloudDocs/ClaudeTracker/latest.json` appears
- Validate JSON parses into `SessionData`

---

## Phase 2: iOS Companion App — iCloud Monitor + WatchConnectivity
**TIER 1 — The bridge between Mac and Watch**

**What to implement:**

1. **`iCloudMonitor.swift`** — watches for `latest.json` changes using `NSMetadataQuery`:
   - On file change → decode `SessionData` → call `WatchRelayManager.send(_:)`
   - Handles first-launch activation and background refresh

2. **`WatchRelayManager.swift`** — `WCSession` sender for iOS:
   - `WCSession.default.activate()`
   - Uses `transferUserInfo(_:)` (reliable background delivery)
   - Encodes `SessionData` as `[String: Any]` dictionary

3. **`claude_tracker_applewatchApp.swift`** (iOS target) — start monitor on launch

**Files:**
```
ClaudeTracker/
├── iCloudMonitor.swift
└── WatchRelayManager.swift
```

**Verification checklist:**
- Drop a valid `latest.json` into iCloud folder manually → confirm `iCloudMonitor` fires
- Confirm `WCSession` delivers `userInfo` to simulator watch

---

## Phase 3: watchOS Core — Receive + Haptic + Dashboard
**TIER 1 — Where the magic happens**

**What to implement:**

1. **`WatchSessionReceiver.swift`** — `WCSessionDelegate` for watchOS:
   - `session(_:didReceiveUserInfo:)` → decode → publish via `@Observable` `TokenStore`
   - Triggers haptic: `WKInterfaceDevice.current().play(.notification)`

2. **`TokenStore.swift`** + **`UsageState.swift`** (Shared) — `@Observable` data store:
   ```swift
   @Observable @MainActor
   final class TokenStore {
       private(set) var sessions: [SessionData] = []
       var pendingCompletion: SessionData? = nil
       private(set) var usageState: UsageState = .mock
   }

   struct UsageState: Codable {
       var utilization5h: Double   // 0.0–1.0
       var utilization7d: Double
       var resetAt5h: Date
       var resetAt7d: Date
       var isMocked: Bool

       static var mock: UsageState {
           UsageState(
               utilization5h: 0.42,
               utilization7d: 0.18,
               resetAt5h: Date().addingTimeInterval(2 * 3600 + 13 * 60),
               resetAt7d: Date().addingTimeInterval(4 * 24 * 3600),
               isMocked: true
           )
       }
   }
   ```

3. **Dashboard UI** — `ContentView.swift`:
   - Usage ring (`utilization5h`) with mock badge
   - Reset countdown ("2hr 13min left")
   - Secondary 7-day indicator
   - `.sheet(item: $store.pendingCompletion)` → `CompletionView`

4. **`CompletionView.swift`** — session completion alert showing tokens + cost

**Verification checklist:**
- Send mock `SessionData` from iOS simulator → watch shows haptic + `CompletionView` appears
- `pendingCompletion` clears after dismissal
- Countdown shows correct time remaining

---

## Phase 4: Limit Reset Alarm
**TIER 2 — Most-requested feature**

**What to implement:**

**`ResetAlarmManager.swift`** — schedules a local notification + strong haptic when the limit window resets:
- `UNUserNotificationCenter` — schedule notification at `limitResetAt`
- On trigger: `WKInterfaceDevice.current().play(.notification)` (strongest haptic)
- Reschedules automatically when a new `SessionData` arrives

**Why this phase matters**: Users want to know the exact moment they can resume full usage — not just track what they've used.

**Verification checklist:**
- Schedule alarm 30 seconds in the future → confirm notification fires + haptic plays
- Confirm alarm reschedules when `limitResetAt` changes

---

## Phase 5: Stats Dashboard + Complications
**TIER 2 — Dashboard & visibility**

**What to implement:**

1. **`StatsView.swift`** — scrollable list of past sessions with token bars

2. **`TokenComplication.swift`** — Watch face complication:
   - Graphic corner: usage % + countdown to reset
   - Circular: usage percentage
   - Uses `WidgetKit` (watchOS supported families only)

3. **`ComplicationProvider.swift`** — `TimelineProvider` reading from App Group `UserDefaults`

**Anti-pattern guards:**
- Complications require App Group entitlement — set up in Xcode first
- Complication timeline needs updates every ~15 min for accurate countdown

---

## Phase 6: Final Verification & QA
**TIER 2 — Before declaring MVP done**

**Checklist:**

- End-to-end test: run a real Claude Code session → hook fires → JSON in iCloud → iOS relays → watch shows haptic + dashboard updates
- Confirm reset countdown is accurate and alarm fires at the right time
- Confirm 2x indicator appears/disappears correctly
- Grep for deprecated APIs: `foregroundColor`, `NavigationView`, `ObservableObject`
- Verify `@State` is always `private`
- Verify no `sendMessage` (use `transferUserInfo` for reliability)
- Confirm hook script has `chmod +x` and runs without errors
- Verify shared files (`Shared/Models.swift`, etc.) are in correct targets via Xcode target membership

---

## Phase 7: Real Usage Ring — Anthropic OAuth API
**TIER 3 — Real data replaces mock**

**Context**: Phases 0–6 build the full MVP using `UsageState.mock`. This phase replaces the mock with real data from the Anthropic OAuth API.

**Why deferred**: OAuth PKCE adds iOS complexity. Building against a mock first lets the core pipeline and all features stabilize.

**What the API provides:**
- `GET /api/oauth/usage` → `five_hour.utilization`, `five_hour.resets_at`, `seven_day.utilization`, `seven_day.resets_at`
- Auth: OAuth 2.0 PKCE. Token storage in iOS Keychain.

**What to implement:**

1. **`AnthropicAPIClient.swift`** (iOS target) — OAuth PKCE client:
   - Browser-based sign-in via `ASWebAuthenticationSession`
   - Token storage in iOS Keychain
   - Auto-refresh 5 min before expiry
   - Exponential backoff on 429 (up to 60-minute cap)
   - Graceful logout on `invalid_grant` / 401

2. **`UsageStatePoller.swift`** (iOS target) — polls `/api/oauth/usage`:
   - 15-minute default interval
   - Reset-timestamp reconciliation (preserve, detect rollover, trust server)
   - Relay to watch via `transferUserInfo`

3. **`TokenStore` update** — set `usageState.isMocked = false` once first real poll succeeds

4. **`ResetAlarmManager` update** — no changes needed (already reads `resetAt5h`)

**Verification checklist:**
- Sign in via OAuth → credentials stored in Keychain
- Poll fires → mock badge disappears from watch
- Simulate 429 → backoff increases correctly
- Simulate server dropping `resets_at` → previous value preserved
- Simulate utilization drop → reset time advances by 5h
- Revoke token → graceful logout, mock badge reappears

**Anti-pattern guards:**
- Do NOT store OAuth tokens in UserDefaults — use Keychain
- Do NOT poll more than every 15 minutes
- Do NOT show the ring as "real" until `isMocked == false`

---

## Phase 8: Context Window Tracking
**TIER 3 — Additional high-value feature**

**Goal**: Show context window fullness on the watch with haptic alerts at thresholds.

**What the data looks like:**
```
Total:        50k / 200k tokens (25%)

By category:
  System prompt:      6.3k  (3.1%)
  System tools:       7.6k  (3.8%)
  Memory files:         205  (0.1%)
  Skills:             1.2k  (0.6%)
  Messages:          35.4k (17.7%)
  Free space:         116k (58.2%)
```

**Why this matters**: Context exhaustion silently degrades response quality. A glanceable gauge on the wrist lets the user act before it becomes a problem.

**Data source**: Claude Code hooks (confirm in Phase 0 which hook exposes context stats).

**What to implement:**

1. **`ContextState.swift`** (Shared):
   ```swift
   struct ContextState: Codable {
       var totalTokens: Int
       var maxTokens: Int
       var utilization: Double     // 0.0–1.0
       var breakdown: ContextBreakdown
       var timestamp: Date
   }

   struct ContextBreakdown: Codable {
       var systemPrompt: Int
       var systemTools: Int
       var memoryFiles: Int
       var skills: Int
       var messages: Int
       var autocompactBuffer: Int
   }
   ```

2. **Stop hook extension** — extend `stop-tracker.sh` to write `context.json` in iCloud

3. **iOS companion update** — `iCloudMonitor` watches `context.json` and relays `ContextState` to watch

4. **watchOS dashboard update** — `TokenStore` gains `contextState: ContextState?`. `ContentView` shows context gauge.

5. **Threshold alerts** — configurable thresholds (default: warn 70%, critical 90%):
   - Warn: yellow indicator + `.notification` haptic
   - Critical: red indicator + stronger haptic
   - Fires only on upward crossing (not repeatedly)

**Anti-pattern guards:**
- Only fire alert on threshold crossing, not on every hook call
- Discard context data if older than 10 minutes
- Confirm exact env var names in Phase 0

---

## Future: Windows / Cross-Platform Support
**Out of scope for now**

The current architecture uses iCloud as the transport layer (Mac-only). To support Windows in the future, replace iCloud with an **HTTP relay**:

```
Stop hook (any OS) → curl POST to relay → iOS app (polling/WebSocket) → WatchConnectivity → watch
```

**Relay options:**
- **ntfy.sh** — zero backend, simple, data goes to public server
- **Supabase Realtime** — free tier, real-time iOS SDK
- **Cloudflare Worker + KV** — cheap, fast, requires deploy

**What changes:**
- `stop-tracker.sh` → add `curl -X POST` to configurable endpoint
- `iCloudMonitor.swift` → replace `NSMetadataQuery` with polling/WebSocket

**What does NOT change:** `SessionData` model, WatchConnectivity relay, all watchOS code.

---

## Reference: claude-usage-bar (Blimp-Labs)

**Repo**: https://github.com/Blimp-Labs/claude-usage-bar

**What it is**: macOS menu bar app showing real-time Claude API utilization via the Anthropic OAuth API.

### How It Works

- **Auth**: OAuth via browser — no manual API keys. User signs in with their Claude account in the browser, gets a token, and the app uses it to query Anthropic's usage endpoints.
- **Endpoints**: Calls the same internal/non-public endpoints that claude.ai itself uses to show usage on the web settings page (`Configuración > Uso`). These are NOT part of the public Anthropic API.
- **Polling**: Queries every 60 seconds for fresh data.
- **Data shown**: 5-hour session utilization %, 7-day weekly limit %, reset countdowns, and historical usage chart (1h/6h/1d/7d/30d).

### OAuth vs Hooks/Screen Time — Real-World Comparison (2026-03-27)

Two competing approaches were compared side-by-side against claude.ai as ground truth:

| Source | 5h Usage | 7d Usage | Freshness |
|---|---|---|---|
| **claude.ai web** (ground truth) | 79% | 33% | "just now" |
| **claude-usage-bar** (OAuth API) | 79% | 33% | "Updated 2 min, 21 sec ago" |
| **Usage for Claude** (hooks/screen time + iCloud) | 24% | 29% | "1 hour ago" |

**Takeaway**: The OAuth-based app matches claude.ai exactly in real time. The hooks/screen-time-based app had stale data (1 hour behind) — likely a bug or polling issue, but it highlights the fundamental reliability advantage of querying the authoritative API directly rather than estimating from hook events or screen time scraping.

### Key Patterns Worth Adopting

1. **OAuth API as authoritative source** — more reliable than estimating from hook data; matches claude.ai exactly
2. **Reset timestamp reconciliation** — preserve, detect rollover, trust server
3. **Threshold-crossing detection** — fire only on upward transition, avoid alert fatigue
4. **Exponential backoff on 429** — smart rate-limit handling
5. **7-day window + extra usage** — track both free and paid credits
6. **Per-model breakdown** — Opus vs Sonnet utilization

These patterns integrate cleanly into the roadmap and should be adopted in Phases 2, 4, 7.

### Implication for ClaudeTracker

Phase 7 (Anthropic OAuth API) is critical for data accuracy. The hook-based pipeline (Phases 1–3) provides session-level events (tokens, cost, haptics on completion), but for **usage ring accuracy**, the OAuth API is the only reliable source. The two approaches are complementary:
- **Hooks** → real-time session completion alerts + per-session token/cost data
- **OAuth API** → authoritative utilization % and reset timestamps for the usage ring
