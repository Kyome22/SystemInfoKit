import os

struct StateClient: DependencyClient {
    private var getState: @Sendable () -> State
    private var setState: @Sendable (State) -> Void

    func withLock<R: Sendable>(_ body: @Sendable (inout State) throws -> R) rethrows -> R {
        var state = getState()
        let result = try body(&state)
        setState(state)
        return result
    }

    static let liveValue: Self = {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        return Self(
            getState: { state.withLock(\.self) },
            setState: { value in state.withLock { $0 = value } }
        )
    }()

    static let testValue = Self(
        getState: { .init() },
        setState: { _ in }
    )

    static func testDependency(_ state: OSAllocatedUnfairLock<State>) -> Self {
        Self(
            getState: { state.withLock(\.self) },
            setState: { value in state.withLock { $0 = value } }
        )
    }
}
