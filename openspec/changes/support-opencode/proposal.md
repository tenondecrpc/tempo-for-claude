## Why

ClaudeTracker currently only reads Claude Code's local data (`~/.claude/stats-cache.json`). OpenCode — an open-source AI coding assistant — stores rich per-message token and cost data in a SQLite DB at `~/.local/share/opencode/opencode.db`. Since the user actively uses both tools, the macOS menu bar app should surface stats from both in a single dashboard, eliminating the need to check two separate tools.

## What Changes

- New `OpenCodeDBReader` that queries `~/.local/share/opencode/opencode.db` for sessions, token counts (input/output/reasoning/cache), cost, model, and provider per assistant message.
- Aggregate OpenCode stats (total tokens, cost, sessions, model breakdown) and expose them alongside existing Claude Code stats.
- New "OpenCode" section in `StatsDetailView` showing session count, token totals, cost, and model/provider breakdown.
- Updated `MacAppCoordinator` wiring to initialize and pass the OpenCode reader.

## Capabilities

### New Capabilities
- `opencode-db-reader`: Read and aggregate usage data (sessions, tokens, cost, models) from OpenCode's local SQLite database.
- `opencode-stats-ui`: Display OpenCode usage statistics in the StatsDetailView alongside Claude Code stats.

### Modified Capabilities
<!-- No existing spec-level requirements change. The stats window gains new sections but its existing behavior is unaffected. -->

## Impact

- **New files**: `OpenCodeDBReader.swift` (macOS target), new StatsDetailView sections
- **Modified files**: `MacAppCoordinator.swift` (wiring), `StatsDetailView.swift` (UI sections)
- **Dependencies**: `sqlite3` (available via system frameworks on macOS — no new packages)
- **Sandbox**: Requires read access to `~/.local/share/opencode/opencode.db` — same home-directory entitlement needed for `~/.claude/`
