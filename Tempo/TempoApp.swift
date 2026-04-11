import SwiftUI

// MARK: - AppCoordinator

/// Wires together iCloud read state, app UI store, and watch relay.
@MainActor
final class AppCoordinator {
    let iCloudReader: iCloudUsageReader
    let store: IOSAppStore
    let relay: WatchRelayManager
    let phoneAlertManager: PhoneAlertManager
    private var hasStartedPhoneAlerts = false

    init() {
        let iCloudReader = iCloudUsageReader()
        let store = IOSAppStore(iCloudReader: iCloudReader)
        let relay = WatchRelayManager()
        let phoneAlertManager = PhoneAlertManager()

        self.iCloudReader = iCloudReader
        self.store = store
        self.relay = relay
        self.phoneAlertManager = phoneAlertManager

        iCloudReader.onUsageState = { [weak relay, weak iCloudReader, weak store] (state: UsageState) in
            relay?.send(
                state,
                history: iCloudReader?.historySnapshots ?? [],
                alertPreferences: store?.sessionAlertPreferences ?? .default
            )
        }
        iCloudReader.onSessionInfo = { [weak relay, weak store, weak phoneAlertManager] (session: SessionInfo) in
            let preferences = store?.sessionAlertPreferences ?? .default
            phoneAlertManager?.notifySessionCompletion(
                for: session,
                enabledInPreferences: preferences.iPhoneAlertsEnabled
            )
            relay?.sendSession(session, alertPreferences: preferences)
        }
        relay.onWatchStateChange = { [weak store] isPaired, isInstalled in
            Task { @MainActor in
                store?.updateWatchState(isPaired: isPaired, isInstalled: isInstalled)
            }
        }
        store.onSessionAlertPreferencesChange = { [weak relay, weak iCloudReader, weak phoneAlertManager] preferences in
            phoneAlertManager?.syncAuthorization(enabledInPreferences: preferences.iPhoneAlertsEnabled)
            if let state = iCloudReader?.latestUsage {
                relay?.send(state, history: iCloudReader?.historySnapshots ?? [], alertPreferences: preferences)
            }
        }
        relay.activate()
        iCloudReader.start()
    }

    // MARK: - Lifecycle

    func onBecomeActive() {
        if hasStartedPhoneAlerts {
            phoneAlertManager.syncAuthorization(enabledInPreferences: store.iPhoneAlertsEnabled)
        } else {
            hasStartedPhoneAlerts = true
            phoneAlertManager.syncAuthorization(enabledInPreferences: store.iPhoneAlertsEnabled)
        }
        iCloudReader.restart()
        store.refreshStaleness()
    }
}

// MARK: - TempoApp

@main
struct TempoApp: App {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(store: coordinator.store)
                .task {
                    if scenePhase == .active {
                        coordinator.onBecomeActive()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        coordinator.onBecomeActive()
                    }
                }
        }
    }
}
