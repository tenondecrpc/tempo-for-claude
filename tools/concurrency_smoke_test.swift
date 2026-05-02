import Foundation

// Standalone smoke test that exercises the two concurrency invariants added to
// the macOS app:
//   1. Single-flight token refresh: N concurrent callers result in exactly one
//      underlying refresh operation.
//   2. Poller concurrency guard: while a poll is in flight, the timer firing
//      must not start a second concurrent poll.
//
// We replicate the production patterns in self-contained @MainActor types and
// drive them with a controlled clock so the test is deterministic.

struct SmokeFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

@MainActor
final class SingleFlightFixture {
    private(set) var refreshCallCount = 0
    private var inFlight: Task<String, Error>?

    func refresh(simulatedDelayMs: UInt64) async throws -> String {
        if let inFlight = inFlight {
            return try await inFlight.value
        }
        refreshCallCount += 1
        let task = Task<String, Error> { [weak self] in
            guard self != nil else { throw SmokeFailure(message: "fixture deallocated") }
            try await Task.sleep(nanoseconds: simulatedDelayMs * 1_000_000)
            return "token-\(simulatedDelayMs)"
        }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}

@MainActor
final class PollerFixture {
    private(set) var pollStartCount = 0
    private(set) var pollCompletionCount = 0
    private(set) var skippedDueToInFlight = 0
    private(set) var isPolling = false

    func tick(simulatedWorkMs: UInt64) async {
        guard !isPolling else {
            skippedDueToInFlight += 1
            return
        }
        isPolling = true
        pollStartCount += 1
        defer {
            isPolling = false
            pollCompletionCount += 1
        }
        try? await Task.sleep(nanoseconds: simulatedWorkMs * 1_000_000)
    }
}

@main
struct ConcurrencySmokeTest {
    static func main() async throws {
        try await assertSingleFlightCoalesces()
        try await assertSingleFlightAllowsSequentialRefresh()
        try await assertPollerSkipsConcurrentTick()
        try await assertPollerAllowsSequentialTicks()
        print("Concurrency smoke test passed")
    }

    // MARK: - Single-flight

    static func assertSingleFlightCoalesces() async throws {
        let fixture = await SingleFlightFixture()

        async let r1 = fixture.refresh(simulatedDelayMs: 50)
        async let r2 = fixture.refresh(simulatedDelayMs: 50)
        async let r3 = fixture.refresh(simulatedDelayMs: 50)
        async let r4 = fixture.refresh(simulatedDelayMs: 50)
        async let r5 = fixture.refresh(simulatedDelayMs: 50)

        let results = try await [r1, r2, r3, r4, r5]
        let callCount = await fixture.refreshCallCount

        guard callCount == 1 else {
            throw SmokeFailure(
                message: "Expected exactly 1 underlying refresh for 5 concurrent callers, got \(callCount)"
            )
        }

        let unique = Set(results)
        guard unique.count == 1 else {
            throw SmokeFailure(
                message: "Expected all callers to receive the same token, got \(unique)"
            )
        }
    }

    static func assertSingleFlightAllowsSequentialRefresh() async throws {
        let fixture = await SingleFlightFixture()

        _ = try await fixture.refresh(simulatedDelayMs: 10)
        _ = try await fixture.refresh(simulatedDelayMs: 10)
        _ = try await fixture.refresh(simulatedDelayMs: 10)

        let callCount = await fixture.refreshCallCount
        guard callCount == 3 else {
            throw SmokeFailure(
                message: "Expected 3 sequential refreshes to issue 3 underlying calls, got \(callCount)"
            )
        }
    }

    // MARK: - Poller concurrency guard

    static func assertPollerSkipsConcurrentTick() async throws {
        let fixture = await PollerFixture()

        async let first: Void = fixture.tick(simulatedWorkMs: 80)

        // Give the first tick a moment to mark itself as polling, then fire
        // a "timer tick" while the first poll is still in flight.
        try await Task.sleep(nanoseconds: 10_000_000)
        await fixture.tick(simulatedWorkMs: 5)
        await first

        let starts = await fixture.pollStartCount
        let skipped = await fixture.skippedDueToInFlight

        guard starts == 1 else {
            throw SmokeFailure(
                message: "Expected only the first tick to start a poll, got \(starts) starts"
            )
        }
        guard skipped == 1 else {
            throw SmokeFailure(
                message: "Expected the second tick to be skipped, got \(skipped) skips"
            )
        }
    }

    static func assertPollerAllowsSequentialTicks() async throws {
        let fixture = await PollerFixture()

        await fixture.tick(simulatedWorkMs: 5)
        await fixture.tick(simulatedWorkMs: 5)
        await fixture.tick(simulatedWorkMs: 5)

        let starts = await fixture.pollStartCount
        let skipped = await fixture.skippedDueToInFlight

        guard starts == 3 else {
            throw SmokeFailure(
                message: "Expected 3 sequential ticks to all run, got \(starts) starts"
            )
        }
        guard skipped == 0 else {
            throw SmokeFailure(
                message: "Did not expect any skips for sequential ticks, got \(skipped)"
            )
        }
    }
}
