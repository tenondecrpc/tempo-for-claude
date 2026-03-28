import Observation
import Foundation

@Observable @MainActor
final class TokenStore {
    private(set) var sessions: [SessionInfo] = []
    var pendingCompletion: SessionInfo? = nil
    private(set) var usageState: UsageState = .mock

    func apply(_ state: UsageState) {
        usageState = state
    }
}
