import os
import Testing

@testable import SystemInfoKit

struct StateClientTests {
    @Test
    func withLock_does_not_lose_concurrent_updates() async {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.interval = 0
        }
        let sut = StateClient.testDependency(state)
        await withTaskGroup { group in
            for _ in 0..<10_000 {
                group.addTask { sut.withLock { $0.interval += 1 } }
            }
        }
        #expect(state.withLock(\.interval) == 10_000)
    }
}
