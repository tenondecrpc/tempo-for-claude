## Purpose

Define filesystem permission requirements for shared widget snapshots.

## Requirements

### Requirement: Widget snapshot files must have restrictive POSIX permissions
The `WidgetUsageSnapshot` write path in `Shared/WidgetUsageSnapshot.swift` SHALL set `0o600` permissions on the snapshot JSON file, matching the pattern used by `CredentialStore`.

#### Scenario: Snapshot file has owner-only permissions
- **WHEN** `WidgetUsageSnapshot` writes a snapshot to the App Group container
- **THEN** `FileManager.default.setAttributes([.posixPermissions: 0o600], ...)` is called on the file after writing

#### Scenario: Permissions applied after atomic write
- **WHEN** the snapshot is written with `.atomic` options
- **THEN** `setAttributes` is called after the write completes to ensure the final file has `0o600`

#### Scenario: Read path is unaffected
- **WHEN** widget extensions read the snapshot file
- **THEN** reads succeed because the extensions share the same App Group container and process owner
