import Foundation
import UserNotifications

final class WatchAlertManager: NSObject {
    private enum DefaultsKey {
        static let lastAlertedSessionID = "watchAlert.lastAlertedSessionID"
    }

    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private var hasRequestedAuthorization = false

    var onAlertStateChange: ((Bool) -> Void)?

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
        super.init()
        center.delegate = self
    }

    func syncAuthorization(enabledInPreferences: Bool) {
        if enabledInPreferences, !hasRequestedAuthorization {
            hasRequestedAuthorization = true
            center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
                if let error {
                    print("[WatchAlert] authorization request failed: \(error)")
                } else {
                    print("[WatchAlert] authorization granted: \(granted)")
                }
                self?.refreshAlertState(enabledInPreferences: enabledInPreferences)
            }
            return
        }

        refreshAlertState(enabledInPreferences: enabledInPreferences)
    }

    func refreshAlertState(enabledInPreferences: Bool) {
        center.getNotificationSettings { [weak self] settings in
            let isEnabled = enabledInPreferences && Self.isNotificationsEnabled(settings.authorizationStatus)
            Task { @MainActor in
                self?.onAlertStateChange?(isEnabled)
            }
        }
    }

    func notifySessionCompletion(for session: SessionInfo, enabledInPreferences: Bool) {
        guard enabledInPreferences else {
            refreshAlertState(enabledInPreferences: enabledInPreferences)
            return
        }
        guard lastAlertedSessionID != session.sessionId else { return }

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            let isEnabled = enabledInPreferences && Self.isNotificationsEnabled(settings.authorizationStatus)
            Task { @MainActor in
                self.onAlertStateChange?(isEnabled)
            }

            guard isEnabled else {
                print("[WatchAlert] authorization missing; skipping session id=\(session.sessionId)")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Claude Code Task Finished"
            content.body = Self.notificationBody(for: session)
            content.sound = .default
            content.userInfo = [
                "type": "SessionInfo",
                "sessionId": session.sessionId,
            ]

            let request = UNNotificationRequest(
                identifier: Self.notificationIdentifier(for: session),
                content: content,
                trigger: nil
            )

            self.center.add(request) { error in
                if let error {
                    print("[WatchAlert] failed to schedule notification for session id=\(session.sessionId): \(error)")
                    return
                }

                self.lastAlertedSessionID = session.sessionId
                print("[WatchAlert] scheduled session completion notification id=\(session.sessionId)")
            }
        }
    }

    private static func isNotificationsEnabled(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional
    }

    private static func notificationIdentifier(for session: SessionInfo) -> String {
        "session-complete.\(session.sessionId)"
    }

    private static func notificationBody(for session: SessionInfo) -> String {
        "\(formatTokens(session.inputTokens + session.outputTokens)) in \(formatDuration(session.durationSeconds))"
    }

    private static func formatTokens(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let value = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return "\(value) tokens"
    }

    private static func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(remainingSeconds)s"
    }

    private var lastAlertedSessionID: String? {
        get { defaults.string(forKey: DefaultsKey.lastAlertedSessionID) }
        set { defaults.setValue(newValue, forKey: DefaultsKey.lastAlertedSessionID) }
    }
}

extension WatchAlertManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        guard userInfo["type"] as? String == "SessionInfo" else {
            completionHandler([.sound, .banner, .list])
            return
        }

        completionHandler([.sound, .banner, .list])
    }
}
