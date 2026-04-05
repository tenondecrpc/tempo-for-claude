## Context

ClaudeTracker's macOS menu bar app reads Claude Code stats from `~/.claude/stats-cache.json` via `ClaudeLocalDBReader` — an `@Observable @MainActor` class instantiated in `MacAppCoordinator` and passed to `StatsDetailView`. The view renders sections conditionally based on `localDB.isAvailable`.

OpenCode stores all session and message data in a SQLite database at `~/.local/share/opencode/opencode.db`. Each assistant message includes a `tokens` object (`input`, `output`, `reasoning`, `cache.read`, `cache.write`, `total`) and a `cost` field, plus `modelID` and `providerID`. Sessions are linked to projects and have timestamps.

## Goals / Non-Goals

**Goals:**
- Read OpenCode session and token data from its SQLite DB
- Aggregate stats: total sessions, total tokens (by type), total cost, model/provider breakdown
- Display OpenCode stats in StatsDetailView as a new collapsible section
- Follow the exact same architectural pattern as ClaudeLocalDBReader

**Non-Goals:**
- Real-time session monitoring or event-driven updates (polling/reload is sufficient)
- Writing to or modifying the OpenCode database
- Importing OpenCode data into the Claude Code stats pipeline
- Supporting OpenCode's auth tokens or API calls
- Merging Claude Code + OpenCode stats into unified charts (they stay in separate sections)

## Decisions

### D1: Mirror ClaudeLocalDBReader's architecture
`OpenCodeDBReader` will be an `@Observable @MainActor final class` with the same load-on-init pattern. This keeps the codebase consistent and the wiring in `MacAppCoordinator` identical.

**Alternative considered**: A shared protocol for both readers. Rejected — the data shapes differ significantly (JSON flat file vs SQLite with relational joins), and a forced abstraction adds complexity without reuse.

### D2: Use system SQLite via `sqlite3` C API
macOS ships with `libsqlite3` — import it via `import SQLite3`. No third-party dependency needed.

**Alternative considered**: GRDB or SQLite.swift. Rejected — adding a SPM dependency for read-only queries on a known schema is overkill.

### D3: Read-only, snapshot approach
Open the DB in read-only mode (`SQLITE_OPEN_READONLY`), run aggregate queries, close immediately. No persistent connection. This avoids locking issues with OpenCode's running process.

### D4: Aggregate via SQL, not Swift
Compute totals (sum tokens, count sessions, group by model) in SQL rather than loading all 389+ messages into memory. This is more efficient and the queries are straightforward.

### D5: Separate UI section, not merged charts
OpenCode stats appear in their own "OpenCode" section in StatsDetailView, below the existing Claude Code local DB sections. This avoids confusion between the two tools' different cost models and token accounting.

## Risks / Trade-offs

- **Schema changes**: OpenCode could change its DB schema in future versions → Mitigation: fail gracefully — if queries fail, set `isAvailable = false` and hide the section. Log the error for debugging.
- **DB locked by OpenCode**: The WAL-mode DB could be briefly locked during writes → Mitigation: `SQLITE_OPEN_READONLY` + `PRAGMA journal_mode` respects WAL readers. SQLite's WAL mode supports concurrent readers.
- **Sandbox entitlement**: Reading `~/.local/share/opencode/` requires the same home-directory read entitlement already needed for `~/.claude/` → No additional entitlement work.
- **No token cost data for free models**: Some OpenCode models report `cost: 0` → Display tokens regardless; show cost only when > 0.
