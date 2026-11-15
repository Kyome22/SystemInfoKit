import os

struct StateClient: DependencyClient {
    private var state: OSAllocatedUnfairLock<State>

    func withLock<R: Sendable>(_ body: @Sendable (inout State) throws -> R) rethrows -> R {
        try state.withLock(body)
    }

    static let liveValue = Self(state: .init(initialState: .init()))

    static var testValue: Self {
        Self(state: .init(initialState: .init()))
    }

    static func testDependency(_ state: OSAllocatedUnfairLock<State>) -> Self {
        Self(state: state)
    }
}
