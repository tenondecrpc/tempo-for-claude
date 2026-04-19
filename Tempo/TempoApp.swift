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

        DevLog.trace(
            "AlertTrace",
            "TempoApp coordinator init initialIPhoneAlerts=\(store.iPhoneAlertsEnabled) initialWatchAlerts=\(store.watchAlertsEnabled)"
        )

        iCloudReader.onUsageState = { [weak relay, weak iCloudReader, weak store] (state: UsageState) in
            DevLog.trace(
                "AlertTrace",
                "TempoApp received usage state utilization5h=\(state.utilization5h) utilization7d=\(state.utilization7d) historyCount=\(iCloudReader?.historySnapshots.count ?? 0)"
            )
            let updatedAt = iCloudReader?.lastReceivedAt ?? Date()
            let appearanceMode = store?.appearanceMode ?? .dark
            let snapshot = WidgetUsageSnapshot(
                usage: state,
                updatedAt: updatedAt,
                appearanceMode: appearanceMode
            )
            if TempoWidgetSnapshotStore.write(snapshot, platform: .iOS) {
                TempoWidgetSnapshotStore.reloadTimelines(for: .iOS)
            }
            relay?.send(
                state,
                history: iCloudReader?.historySnapshots ?? [],
                alertPreferences: store?.sessionAlertPreferences ?? .default,
                appearanceMode: appearanceMode
            )
        }
        iCloudReader.onSessionInfo = { [weak relay, weak store, weak phoneAlertManager] (session: SessionInfo) in
            let preferences = store?.sessionAlertPreferences ?? .default
            let appearanceMode = store?.appearanceMode ?? .dark
            DevLog.trace(
                "AlertTrace",
                "TempoApp received synced session id=\(session.sessionId) iPhoneAlerts=\(preferences.iPhoneAlertsEnabled) watchAlerts=\(preferences.watchAlertsEnabled)"
            )
            phoneAlertManager?.notifySessionCompletion(
                for: session,
                enabledInPreferences: preferences.iPhoneAlertsEnabled
            )
            relay?.sendSession(session, alertPreferences: preferences, appearanceMode: appearanceMode)
        }
        iCloudReader.onAlertPreferences = { [weak store] preferences in
            DevLog.trace(
                "AlertTrace",
                "TempoApp received synced alert preferences iPhone=\(preferences.iPhoneAlertsEnabled) watch=\(preferences.watchAlertsEnabled)"
            )
            Task { @MainActor in
                store?.applySyncedAlertPreferences(preferences)
            }
        }
        iCloudReader.onAppearanceMode = { [weak self] appearanceMode in
            Task { @MainActor in
                self?.store.applySyncedAppearanceMode(appearanceMode)
                self?.refreshWidgetAppearance(appearanceMode)
                self?.relay.sendAppearanceMode(appearanceMode)
                if let state = self?.iCloudReader.latestUsage {
                    self?.relay.send(
                        state,
                        history: self?.iCloudReader.historySnapshots ?? [],
                        alertPreferences: self?.store.sessionAlertPreferences ?? .default,
                        appearanceMode: appearanceMode
                    )
                }
            }
        }
        relay.onWatchStateChange = { [weak store] isPaired, isInstalled in
            Task { @MainActor in
                store?.updateWatchState(isPaired: isPaired, isInstalled: isInstalled)
            }
        }
        store.onSessionAlertPreferencesChange = { [weak relay, weak iCloudReader, weak phoneAlertManager, weak store] preferences in
            DevLog.trace(
                "AlertTrace",
                "TempoApp local preference change iPhone=\(preferences.iPhoneAlertsEnabled) watch=\(preferences.watchAlertsEnabled)"
            )
            phoneAlertManager?.syncAuthorization(enabledInPreferences: preferences.iPhoneAlertsEnabled)
            if let state = iCloudReader?.latestUsage {
                relay?.send(
                    state,
                    history: iCloudReader?.historySnapshots ?? [],
                    alertPreferences: preferences,
                    appearanceMode: store?.appearanceMode ?? .dark
                )
            }
            do {
                try AlertPreferencesSync.write(preferences)
            } catch {}
        }
        relay.activate()
        DevLog.trace("AlertTrace", "TempoApp requested WatchRelay activation")
        iCloudReader.start()
        DevLog.trace("AlertTrace", "TempoApp started iCloudUsageReader from coordinator init")
    }

    // MARK: - Lifecycle

    func onBecomeActive() {
        DevLog.trace(
            "AlertTrace",
            "TempoApp became active iPhoneAlerts=\(store.iPhoneAlertsEnabled) watchAlerts=\(store.watchAlertsEnabled)"
        )
        if hasStartedPhoneAlerts {
            phoneAlertManager.syncAuthorization(enabledInPreferences: store.iPhoneAlertsEnabled)
        } else {
            hasStartedPhoneAlerts = true
            phoneAlertManager.syncAuthorization(enabledInPreferences: store.iPhoneAlertsEnabled)
        }
        iCloudReader.restart()
        store.refreshStaleness()
    }

    private func refreshWidgetAppearance(_ appearanceMode: AppearanceMode) {
        guard let snapshot = TempoWidgetSnapshotStore.read(platform: .iOS) else { return }
        let refreshedSnapshot = WidgetUsageSnapshot(snapshot: snapshot, appearanceMode: appearanceMode)
        if TempoWidgetSnapshotStore.write(refreshedSnapshot, platform: .iOS) {
            TempoWidgetSnapshotStore.reloadTimelines(for: .iOS)
        }
    }
}

// MARK: - TempoApp

@main
struct TempoApp: App {
    @State private var coordinator = AppCoordinator()
    @State private var widgetRoute: TempoWidgetRoute?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(store: coordinator.store, widgetRoute: widgetRoute)
                .applyClaudeAppearance(coordinator.store.appearanceMode)
                .task {
                    DevLog.trace("AlertTrace", "TempoApp ContentView task scenePhase=\(String(describing: scenePhase))")
                    if scenePhase == .active {
                        coordinator.onBecomeActive()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    DevLog.trace("AlertTrace", "TempoApp scenePhase changed to \(String(describing: phase))")
                    if phase == .active {
                        coordinator.onBecomeActive()
                    }
                }
                .onOpenURL { url in
                    widgetRoute = TempoWidgetRoute(url: url)
                }
        }
    }
}
