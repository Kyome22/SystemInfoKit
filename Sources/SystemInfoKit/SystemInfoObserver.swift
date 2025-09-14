@preconcurrency import Combine
import Foundation
import os

public final class SystemInfoObserver: Sendable {
    public static let shared = SystemInfoObserver()

    private let dependencies: Dependencies
    private let language: Language
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
        language: Language
    ) {
        self.dependencies = dependencies
        self.language = language
    }

    public convenience init() {
        self.init(dependencies: .init(), language: .automatic)
    }

    public func startMonitoring(monitorInterval: Double = 5.0) {
        dependencies.stateClient.withLock { $0.interval = max(monitorInterval, 1.0) }
        let queue = DispatchQueue(label: "SystemInfoKit.NWPathMonitor", qos: .utility)
        dependencies.nwPathMonitorClient.start(queue)
        let timer = Timer
            .publish(every: monitorInterval, on: RunLoop.main, in: .common)
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
        dependencies.nwPathMonitorClient.cancel()
    }

    public func toggleActivation(requests: [SystemInfoType: Bool]) {
        dependencies.stateClient.withLock {
            $0.activationState.merge(requests) { _, new in new }
        }
    }

    private func updateSystemInfo() {
        Task {
            for type in SystemInfoType.allCases {
                let repository = type.repositoryType.init(dependencies, language: language)
                if dependencies.stateClient.withLock(\.activationState[type]) ?? false {
                    await repository.update()
                } else {
                    repository.reset()
                }
            }
            systemInfoSubject.send(dependencies.stateClient.withLock(\.bundle))
        }
    }
}
