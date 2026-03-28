import SwiftUI

// MARK: - WelcomeWindowView

struct WelcomeWindowView: View {
    let coordinator: MacAppCoordinator
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var pastedCode = ""
    @State private var isSubmitting = false
    @State private var signInError: String?
    @State private var isRestoringSession = false

    var body: some View {
        ZStack {
            ClaudeTheme.background.ignoresSafeArea()

            if coordinator.authState.isAwaitingCode {
                codeEntryView
            } else {
                welcomeView
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: coordinator.authState.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && !isRestoringSession {
                dismissWindow(id: "welcome")
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Welcome to Usage for Claude")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ClaudeTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Track your Claude Usage for Claude right from your menu bar or widget.")
                    .font(.body)
                    .foregroundStyle(ClaudeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            menuBarPreview
                .frame(maxWidth: 300)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    Task {
                        isRestoringSession = true
                        coordinator.authState.requiresExplicitSignIn = false
                        let start = Date()
                        let restored = await coordinator.client.tryRestoreSession()
                        let elapsed = Date().timeIntervalSince(start)
                        if elapsed < 2 {
                            try? await Task.sleep(nanoseconds: UInt64((2 - elapsed) * 1_000_000_000))
                        }
                        isRestoringSession = false
                        if restored {
                            coordinator.onAuthenticated()
                            dismissWindow(id: "welcome")
                        } else {
                            coordinator.client.startOAuthFlow()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRestoringSession {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "terminal.fill")
                        }
                        Text("Sign in with Claude Code")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(ClaudeTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isRestoringSession)

                Button {
                    // Placeholder — Coming Soon
                } label: {
                    Label("Sign in with Email", systemImage: "envelope")
                        .font(.headline)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(ClaudeTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ClaudeTheme.progressTrack, lineWidth: 1)
                )
                .disabled(true)
                .help("Coming Soon")
            }
        }
        .padding(40)
    }

    // MARK: - Code Entry View

    private var codeEntryView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(ClaudeTheme.accent)

            VStack(spacing: 8) {
                Text("Paste Authorization Code")
                    .font(.title2.bold())
                    .foregroundStyle(ClaudeTheme.textPrimary)
                Text("After authorizing in the browser, paste the code shown on screen.")
                    .font(.body)
                    .foregroundStyle(ClaudeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("code#state", text: $pastedCode)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)

            if let error = signInError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(ClaudeTheme.destructive)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    pastedCode = ""
                    signInError = nil
                    coordinator.authState.isAwaitingCode = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(ClaudeTheme.textSecondary)

                Button("Submit") {
                    Task { await submitCode() }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(pastedCode.isEmpty || isSubmitting ? ClaudeTheme.progressTrack : ClaudeTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(pastedCode.isEmpty || isSubmitting)
            }

            Spacer()
        }
        .padding(40)
    }

    // MARK: - Menu Bar Preview Mockup

    private var menuBarPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("Usage for Claude")
                    .font(.subheadline.bold())
                    .foregroundStyle(ClaudeTheme.textPrimary)
                Spacer()
                Image(systemName: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(ClaudeTheme.textSecondary)
                Image(systemName: "message")
                    .font(.caption)
                    .foregroundStyle(ClaudeTheme.textSecondary)
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(ClaudeTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().overlay(ClaudeTheme.progressTrack)

            VStack(alignment: .leading, spacing: 6) {
                Group {
                    Text("Current Session")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                    Text("49%")
                        .font(.title3.bold())
                        .foregroundStyle(ClaudeTheme.textPrimary)
                    UsageProgressBar(progress: 0.49)
                    Text("Resets in 13 min (20:00)")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                }

                Spacer().frame(height: 2)

                Group {
                    Text("Weekly Limit")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                    Text("4%")
                        .font(.title3.bold())
                        .foregroundStyle(ClaudeTheme.textPrimary)
                    UsageProgressBar(progress: 0.04)
                    Text("Resets Sun, 15:00")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                }

                Spacer().frame(height: 2)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("On track · 10.5%/hr")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                    Text("just now")
                        .font(.caption2)
                        .foregroundStyle(ClaudeTheme.textSecondary)
                }
            }
            .padding(14)
        }
        .background(ClaudeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ClaudeTheme.progressTrack, lineWidth: 1)
        )
    }

    // MARK: - Submit

    private func submitCode() async {
        isSubmitting = true
        signInError = nil
        defer { isSubmitting = false }
        do {
            try await coordinator.client.submitOAuthCode(pastedCode)
            pastedCode = ""
            coordinator.onAuthenticated()
        } catch {
            signInError = error.localizedDescription
        }
    }
}
