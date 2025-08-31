import os

struct SystemInfoStateClient: DependencyClient {
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

    static let testValue = Self(
        getState: { .init() },
        setState: { _ in }
    )
}
