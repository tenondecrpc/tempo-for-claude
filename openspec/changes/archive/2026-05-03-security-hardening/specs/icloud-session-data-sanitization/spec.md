## ADDED Requirements

### Requirement: Project directory names must not be exposed in iCloud session data

The `SessionEventWriter` in `Tempo macOS/SessionEventWriter.swift` SHALL sanitize `projectDirName` before embedding it in the `sessionId` written to `latest.json` in iCloud. The raw project directory name (e.g., `-Users-alice-Projects-my-app`) exposes the user's filesystem structure.

#### Scenario: Session ID uses hashed directory name

- **WHEN** `parseSessionInfo(from:)` constructs the `sessionID`
- **THEN** the `projectDirName` component is replaced with a SHA-256 hash (first 12 hex characters) of the directory name instead of the raw name

#### Scenario: Hash is deterministic

- **WHEN** the same project directory produces multiple sessions
- **THEN** the hashed prefix is identical across sessions, preserving session grouping by project

#### Scenario: Session ID format preserved

- **WHEN** the hashed directory name is applied
- **THEN** the `sessionID` format remains `"<hash>:<sessionBaseName>"` with no other structural changes

#### Scenario: Fallback for empty directory name

- **WHEN** `projectDirName` is empty or nil
- **THEN** the hash component SHALL be the string `"unknown"` rather than an empty hash
