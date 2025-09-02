@preconcurrency import Combine
import Foundation
import os

public final class SystemInfoObserver: Sendable {
    public static func shared(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        SystemInfoObserver(dependencies: .init(), monitorInterval: monitorInterval)
    }

    private let dependencies: Dependencies
    private let protectedTimer = OSAllocatedUnfairLock<AnyCancellable?>(initialState: nil)

    private let systemInfoSubject = PassthroughSubject<SystemInfoBundle, Never>()
    public func systemInfoStream() -> AsyncStream<SystemInfoBundle> {
        AsyncStream { continuation in
            let cancellable = systemInfoSubject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    init(
        dependencies: Dependencies,
        monitorInterval: Double
    ) {
        self.dependencies = dependencies
        dependencies.stateClient.withLock { $0.interval = max(monitorInterval, 1.0) }
    }

    public func startMonitoring() {
        let interval = dependencies.stateClient.withLock(\.interval)
        let timer = Timer
            .publish(every: interval, on: RunLoop.main, in: .common)
            .autoconnect()
            .prepend(Date())
            .sink { [weak self] _ in
                self?.updateSystemInfo()
            }
        protectedTimer.withLock { $0 = timer }
    }

    public func stopMonitoring() {
        protectedTimer.withLock {
            $0?.cancel()
            $0 = nil
        }
    }

    public func toggleActivation(requests: [SystemInfoType: Bool]) {
        dependencies.stateClient.withLock {
            $0.activationState.merge(requests) { _, new in new }
        }
    }

    private func updateSystemInfo() {
        SystemInfoType.allCases.forEach { type in
            let repository = type.repositoryType.init(dependencies)
            if dependencies.stateClient.withLock(\.activationState[type]) ?? false {
                repository.update()
            } else {
                repository.reset()
            }
        }
        systemInfoSubject.send(dependencies.stateClient.withLock(\.bundle))
    }
}
