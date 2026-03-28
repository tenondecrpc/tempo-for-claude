import SwiftUI

// MARK: - AppCoordinator

/// Wires together AuthState, AnthropicAPIClient, UsageStatePoller, and WatchRelayManager.
/// Held as @State in ClaudeTrackerApp so it lives for the duration of the app.
@MainActor
final class AppCoordinator {
    let authState: AuthState
    let relay: WatchRelayManager
    let client: AnthropicAPIClient
    let poller: UsageStatePoller

    init() {
        let authState = AuthState()
        let relay = WatchRelayManager()
        let client = AnthropicAPIClient(authState: authState)
        let poller = UsageStatePoller(client: client)

        self.authState = authState
        self.relay = relay
        self.client = client
        self.poller = poller

        // Wire callbacks. Use weak references to avoid retain cycles.
        client.onSignOut = { [weak poller] in poller?.stop() }
        poller.onUsageState = { [weak relay] state in relay?.send(state) }
    }

    // MARK: - Lifecycle (Tasks 6.2–6.3)

    /// Called when the app becomes active (foreground).
    func onBecomeActive() {
        relay.activate()  // Idempotent — safe to call every time
        if authState.isAuthenticated {
            poller.start()
        }
    }
}

// MARK: - ClaudeTrackerApp

@main
struct ClaudeTrackerApp: App {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(
                authState: coordinator.authState,
                client: coordinator.client
            )
            // Task 6.2: relay activated + poller started on foreground
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    coordinator.onBecomeActive()
                case .background:
                    coordinator.poller.stop()
                default:
                    break
                }
            }
            // Task 6.3: poller starts immediately after sign-in completes
            // Task 6.4: poller.onUsageState → relay.send is wired in AppCoordinator.init
            .onChange(of: coordinator.authState.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    coordinator.poller.start()
                }
                // stop is handled by client.onSignOut → poller.stop()
            }
        }
    }
}
