import Foundation
import WatchConnectivity

// MARK: - WatchRelayManager (Tasks 5.1–5.4)

final class WatchRelayManager: NSObject {

    // MARK: - Activation (Task 5.2)

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send UsageState (Task 5.4)

    func send(_ state: UsageState) {
        guard WCSession.default.activationState == .activated else { return }
        // Cancel stale UsageState transfers before enqueueing a new one.
        // This prevents a burst of outdated snapshots when the watch reconnects.
        // NOTE: Never cancel SessionInfo transfers — every session event must be delivered.
        WCSession.default.outstandingUserInfoTransfers
            .filter { ($0.userInfo["type"] as? String) == "UsageState" }
            .forEach { $0.cancel() }
        WCSession.default.transferUserInfo(state.toUserInfo())
    }
}

// MARK: - WCSessionDelegate (Task 5.3)

extension WatchRelayManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // Activation complete; any queued transferUserInfo calls can now proceed.
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // User is switching the paired Apple Watch. Stop sending during transition.
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for the newly paired watch.
        WCSession.default.activate()
    }
}

// MARK: - UsageState WatchConnectivity Encoding (Task 5.5)

extension UsageState {
    func toUserInfo() -> [String: Any] {
        [
            "type": "UsageState",
            "utilization5h": utilization5h,
            "utilization7d": utilization7d,
            "resetAt5h": resetAt5h.timeIntervalSince1970,
            "resetAt7d": resetAt7d.timeIntervalSince1970,
            "isMocked": isMocked,
        ]
    }
}
