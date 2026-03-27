import Foundation

struct SessionInfo: Codable, Identifiable {
    let sessionId: String
    let inputTokens: Int
    let outputTokens: Int
    let costUSD: Double
    let durationSeconds: Int
    let timestamp: Date
    let limitResetAt: Date?
    let isDoubleLimitActive: Bool

    var id: String { sessionId }
}

struct UsageState: Codable {
    var utilization5h: Double
    var utilization7d: Double
    var resetAt5h: Date
    var resetAt7d: Date
    var isMocked: Bool

    static var mock: UsageState {
        UsageState(
            utilization5h: 0.42,
            utilization7d: 0.18,
            resetAt5h: Date().addingTimeInterval(2 * 3600 + 13 * 60),
            resetAt7d: Date().addingTimeInterval(4 * 24 * 3600),
            isMocked: true
        )
    }
}
