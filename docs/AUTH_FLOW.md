# Tempo Authentication Flow

This document describes the current macOS authentication behavior.

## Credential Sources

Tempo has two possible credential sources for Anthropic usage API calls:

1. **Tempo OAuth credentials** stored in the macOS Keychain under service `com.tenondev.tempo.claude.oauth`.
2. **Claude Code CLI access token** read from the macOS Keychain item `Claude Code-credentials`.

Tempo OAuth is the preferred source. Claude Code CLI credentials are a read-only fallback.

## Restore Order

On launch and when the user clicks "Sign in with Claude Code", Tempo restores authentication in this order:

1. Load Tempo OAuth credentials from Keychain.
2. If the Tempo access token is valid, use it.
3. If the Tempo access token is expired, refresh it with Tempo's own refresh token and save the refreshed Tempo credentials back to Keychain.
4. If Tempo OAuth credentials are unavailable or cannot be refreshed, read Claude Code CLI credentials.
5. Use Claude Code CLI credentials only when the CLI access token is still fresh.
6. If no valid Tempo credentials and no fresh Claude Code CLI access token exist, start the Tempo OAuth browser flow.

## Request Order

For usage API requests, Tempo uses this order:

1. Tempo OAuth credentials.
2. Fresh Claude Code CLI access token fallback.

If a Tempo OAuth request returns 401, Tempo refreshes only Tempo OAuth credentials and retries once.

If a Claude Code CLI request returns 401, Tempo does not refresh Claude Code credentials. It falls back to Tempo OAuth if available; otherwise the request fails and the user must sign in through Tempo OAuth.

## Claude Code Isolation

Tempo must not write, delete, or refresh Claude Code's own credentials.

Allowed:

- Read the Claude Code Keychain item to obtain a fresh access token.
- Read `~/.claude.json` to display the detected Claude Code account label.
- Read `~/.claude/` project JSONL files for local session stats after the user grants folder access.

Not allowed:

- Use Claude Code's refresh token.
- Write a refreshed token back to Claude Code's Keychain item.
- Delete Claude Code's Keychain item.
- Treat local Claude Code session data as the source for account utilization.

## Sign-Out

Tempo sign-out deletes only Tempo OAuth credentials and clears Tempo's local polling state, including persisted rate-limit backoff. It does not change the Claude Code terminal session.

Claude Code sign-out removes the CLI Keychain item. If Tempo has valid OAuth credentials, it continues using `source=webOAuth`. If Tempo has no valid OAuth credentials, it asks the user to sign in through Tempo OAuth.
