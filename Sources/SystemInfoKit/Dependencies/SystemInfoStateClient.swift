import os

struct SystemInfoStateClient {
    private var getState: @Sendable () -> SystemInfoState
    private var setState: @Sendable (SystemInfoState) -> Void

    func withLock<R: Sendable>(_ body: @Sendable (inout SystemInfoState) throws -> R) rethrows -> R {
        var state = getState()
        let result = try body(&state)
        setState(state)
        return result
    }

    static let liveValue: Self = {
        let state = OSAllocatedUnfairLock<SystemInfoState>(initialState: .init())
        return Self(
            getState: { state.withLock(\.self) },
            setState: { value in state.withLock { $0 = value } }
        )
    }()

    static func testValue(_ state: OSAllocatedUnfairLock<SystemInfoState>) -> Self {
        Self(
            getState: { state.withLock(\.self) },
            setState: { value in state.withLock { $0 = value } }
        )
    }
}
