import SwiftUI
import AuthenticationServices

// MARK: - ContentView (Task 6.1)

struct ContentView: View {
    let authState: AuthState
    let client: AnthropicAPIClient

    @State private var isSigningIn = false
    @State private var signInError: String?

    var body: some View {
        if authState.isAuthenticated {
            connectedView
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
                Task { await signIn() }
            } label: {
                Group {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign in with Claude")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSigningIn)
            .padding(.horizontal)
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

    // MARK: - Sign In Action

    private func signIn() async {
        isSigningIn = true
        signInError = nil
        defer { isSigningIn = false }
        do {
            try await client.signIn()
        } catch let error as ASWebAuthenticationSessionError
            where error.code == .canceledLogin {
            // User dismissed the browser — not an error worth surfacing
        } catch {
            signInError = error.localizedDescription
        }
    }
}
