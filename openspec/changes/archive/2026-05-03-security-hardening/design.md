## Context

Tempo for Claude is a three-platform Apple ecosystem app (macOS, iOS, watchOS) that tracks Claude Code token usage and delivers haptic alerts. The macOS app handles usage authentication via Tempo OAuth credentials in Keychain, with a fresh Claude Code CLI access token as a read-only fallback. Tempo never refreshes, writes, or deletes Claude Code's own credentials. The iOS app reads synced usage data and retains its scoped Keychain OAuth helper for legacy/direct flows. Usage data syncs via iCloud, and session data relays through WatchConnectivity.

A security audit on 2026-05-03 identified 9 findings. The OAuth PKCE implementation is sound (correct `SecRandomCopyBytes`, S256 challenge, code verifier cleanup), but several hardening items need attention.

## Goals / Non-Goals

**Goals:**

- Eliminate plaintext credential storage on macOS
- Reduce sensitive data exposure in logs and iCloud
- Harden OAuth CSRF defenses
- Align macOS and iOS credential storage patterns
- Prepare for App Store distribution with sandbox

**Non-Goals:**

- Certificate pinning (acceptable for this use case)
- Dedicated server push infrastructure (out of scope)
- Linux credential storage (not applicable to Apple ecosystem)
- Multi-account support (separate backlog item)

## Decisions

1. **Keychain as primary store on macOS**: The iOS side already uses Keychain correctly. macOS should follow the same pattern for consistency and security. The existing file path serves as a migration source.

2. **OAuth state validation is unconditional**: The current conditional validation (only when URL has `#` fragment) creates a CSRF gap. The fix rejects codes without state, which is safe because the macOS flow uses user copy-paste (state is always available in `pendingOAuthState`).

3. **SHA-256 hash for project directory names**: A 12-character hex prefix preserves session grouping by project while hiding filesystem structure. Deterministic hashing ensures consistency across sessions.

4. **App Sandbox is conditional**: The code already handles both sandboxed and non-sandboxed modes via `isSandboxed` checks. The entitlement is added for App Store builds; direct distribution may omit it.

5. **Cache TTL matches CLI**: The Claude Code CLI uses 30-second cache TTL. Tempo's 5-minute cache is unnecessarily long and could serve stale tokens.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Keychain migration could lose credentials if interrupted | Read file first, write to Keychain, then delete file. If Keychain write fails, file remains. |
| Unconditional state validation could break edge cases | The macOS flow always has `pendingOAuthState` set before opening the browser. iOS flow uses ASWebAuthenticationSession which preserves state. |
| Hashing project names breaks existing iCloud session data | Old `latest.json` files will have raw names; new files will have hashes. This is a one-time transition. |
| App Sandbox may break non-App Store builds | The `isSandboxed` check already handles both modes. Sandbox is only required for App Store. |
| Reducing cache TTL increases Keychain reads | 30 seconds is the same as the CLI. Keychain reads are fast and the impact is negligible. |
