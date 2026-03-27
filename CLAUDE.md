# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Apple Watch app that tracks Claude Code token/credit usage and delivers haptic alerts when a session ends.

**Pipeline**: Claude Code Stop hook → iCloud JSON → iOS companion → WatchConnectivity (`transferUserInfo`) → watchOS haptic + UI

## Build

Open `ClaudeTracker.xcodeproj` in Xcode. No CLI build system.

## Targets

| Folder | Target | Role |
|---|---|---|
| `ClaudeTracker/` | iOS app | iCloud monitor, WatchConnectivity sender, OAuth poller |
| `ClaudeTracker Watch/` | watchOS app shell | Entry point only |
| `ClaudeTracker Watch Extension/` | watchOS extension | All watch UI and logic |

## Status

Watch dashboard implemented with mocked usage ring. iOS and iCloud pipeline not yet implemented. See `docs/FUTURE_PLAN.md` for the full roadmap.

## Technical Patterns

### SwiftUI @Observable & Bindings (iOS 17+)
- **Problem**: Compiler fails to infer types or provide bindings for `@Observable` properties in `@State`.
- **Solution**: Use `@Bindable` inside the `body` and provide explicit type annotations in closures.
- **Example**:
  ```swift
  var body: some View {
      @Bindable var bindableStore = store // Avoid shadowing
      ...
      .sheet(item: $bindableStore.pendingCompletion) { (item: SessionInfo) in ... }
  }
  ```

### Xcode Project Structure
- **Shared Folder**: Logic shared between targets MUST live in `Shared/`.
- **Synchronization**: The project uses `PBXFileSystemSynchronizedRootGroup`. The `Shared` folder is explicitly added as a synchronized group and linked to all targets in `project.pbxproj` to ensure visibility.

## Shared Logic Pattern

Code shared between targets lives in `Shared/`. Each file in `Shared/` must be added to every relevant target in Xcode (File Inspector → Target Membership).

**Current shared files:**

| File | Used by |
|---|---|
| `Shared/Models.swift` | iOS, watchOS — `SessionData`, `UsageState` |

**Rule**: Never duplicate a model or utility. If both the iOS companion and the watch extension need the same type (e.g. `SessionData`, `UsageState`), it belongs in `Shared/`, not in either target folder.

**Adding a new shared file:**
1. Create the file under `Shared/`
2. In Xcode → File Inspector → Target Membership: check every target that needs it
3. Do NOT copy the file into individual target folders

**What belongs in `Shared/`:**
- Data models (`SessionData`, `UsageState`) — decoded on iOS, displayed on watchOS
- Pure business logic with no platform-specific imports (no `UIKit`, `WatchKit`, `SwiftUI`)
- Shared constants or enums

**What does NOT belong in `Shared/`:**
- Views (SwiftUI layout is platform-specific in this project)
- `WCSession` logic (different delegate on iOS vs watchOS)
- iCloud / `NSMetadataQuery` code (iOS-only)
- Haptic code (watchOS-only)

## Workflow

- **Design**: use `/opsx:propose` to draft changes before implementing
- **SwiftUI**: invoke `/swiftui-expert-skill` when writing or reviewing any Swift/SwiftUI code
