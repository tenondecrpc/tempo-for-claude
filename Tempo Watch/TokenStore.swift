import Observation
import Foundation

@Observable @MainActor
final class TokenStore {
    private(set) var sessions: [SessionInfo] = []
    var pendingCompletion: SessionInfo? = nil
    private(set) var usageState: UsageState = .mock
    private(set) var usageHistory: [UsageHistorySnapshot] = []
    private(set) var appearanceMode: AppearanceMode = .dark
    private(set) var areNotificationsEnabled = false
    private(set) var watchAlertsEnabledInPreferences = SessionAlertPreferences.default.watchAlertsEnabled

    var lastSession: SessionInfo? {
        sessions.max(by: { $0.timestamp < $1.timestamp })
    }

    init() {
        if let rawAppearanceMode = UserDefaults(suiteName: TempoWatchShared.appGroupIdentifier)?
            .string(forKey: TempoWatchShared.appearanceModeKey),
           let parsedAppearanceMode = AppearanceMode(rawValue: rawAppearanceMode) {
            appearanceMode = parsedAppearanceMode
        }
    }

    func apply(_ state: UsageState) {
        usageState = state
    }

    func applyHistory(_ snapshots: [UsageHistorySnapshot]) {
        usageHistory = snapshots
    }

    func applySession(_ session: SessionInfo) {
        sessions.removeAll { $0.sessionId == session.sessionId }
        sessions.append(session)
        sessions.sort { $0.timestamp < $1.timestamp }
        pendingCompletion = session
    }

    func applyAppearanceMode(_ appearanceMode: AppearanceMode) {
        self.appearanceMode = appearanceMode
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        areNotificationsEnabled = enabled
    }

    func setWatchAlertsEnabledInPreferences(_ enabled: Bool) {
        watchAlertsEnabledInPreferences = enabled
    }
}
