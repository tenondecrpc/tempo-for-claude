import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    let authState: AuthState
    let client: AnthropicAPIClient

    @State private var pastedCode = ""
    @State private var isSubmitting = false
    @State private var signInError: String?

    var body: some View {
        if authState.isAuthenticated {
            connectedView
        } else if authState.isAwaitingCode {
            codeEntryView
        } else {
            signInView
        }
    }

    // MARK: - Sign-in Screen

    private var signInView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Claude Tracker")
                .font(.title.bold())
            Text("Sign in to sync your Claude usage to Apple Watch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let error = signInError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            Spacer()
            Button {
                signInError = nil
                client.startOAuthFlow()
            } label: {
                Text("Sign in with Claude")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Code Entry Screen

    private var codeEntryView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Paste Authorization Code")
                .font(.title2.bold())
            Text("After authorizing in the browser, paste the code shown on screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            TextField("code#state", text: $pastedCode)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
            if let error = signInError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            Spacer()
            Button {
                Task { await submitCode() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pastedCode.isEmpty || isSubmitting)
            .padding(.horizontal)

            Button("Cancel") {
                pastedCode = ""
                signInError = nil
                authState.isAwaitingCode = false
            }
            .padding(.bottom)
        }
    }

    // MARK: - Connected Screen

    private var connectedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Connected")
                .font(.title.bold())
            Text("Your Claude usage is syncing to Apple Watch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("Sign Out", role: .destructive) {
                client.signOut()
            }
            .padding(.bottom)
        }
    }

    // MARK: - Submit Code

    private func submitCode() async {
        isSubmitting = true
        signInError = nil
        defer { isSubmitting = false }
        do {
            try await client.submitOAuthCode(pastedCode)
            pastedCode = ""
        } catch {
            signInError = error.localizedDescription
        }
    }
}
