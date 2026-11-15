import Foundation
import Network
import os

public final class SystemInfoObserver: Sendable {
    public static let shared = SystemInfoObserver()

    private let dependencies: Dependencies
    private let language: Language
    private let stream: AsyncStream<SystemInfoBundle>
    private let continuation: AsyncStream<SystemInfoBundle>.Continuation
    private let monitoringTask = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)

    public var currentSystemInfo: SystemInfoBundle {
        dependencies.stateClient.withLock(\.bundle)
    }

    init(dependencies: Dependencies, language: Language) {
        self.dependencies = dependencies
        self.language = language
        let (stream, continuation) = AsyncStream<SystemInfoBundle>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        self.stream = stream
        self.continuation = continuation
    }

    convenience init() {
        self.init(dependencies: .init(), language: .automatic)
    }

    public func systemInfoStream() -> AsyncStream<SystemInfoBundle> {
        stream
    }

    public func startMonitoring(monitorInterval: Double = 5.0) {
        monitoringTask.withLock { monitoringTask in
            guard monitoringTask == nil else { return }

            let interval = max(monitorInterval, 1.0)
            let pathMonitor = NWPathMonitor()
            dependencies.stateClient.withLock {
                $0.interval = interval
                $0.pathMonitor = pathMonitor
            }
            let queue = DispatchQueue(label: "SystemInfoKit.NWPathMonitor", qos: .utility)
            dependencies.nwPathMonitorClient.start(pathMonitor, queue)

            monitoringTask = Task { [weak self] in
                await self?.monitor(interval: interval)
            }
        }
    }

    private func monitor(interval: Double) async {
        await updateSystemInfo()
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(interval))
            } catch {
                return
            }
            await updateSystemInfo()
        }
    }

    public func stopMonitoring() {
        monitoringTask.withLock { monitoringTask in
            monitoringTask?.cancel()
            monitoringTask = nil
            if let pathMonitor = dependencies.stateClient.withLock({ $0.pathMonitor.take() }) {
                dependencies.nwPathMonitorClient.cancel(pathMonitor)
            }
        }
    }

    public func toggleActivation(requests: [SystemInfoType: Bool]) {
        let changes = dependencies.stateClient.withLock { state in
            let changes = requests.filter { (state.activationState[$0.key] ?? false) != $0.value }
            state.activationState.merge(requests) { _, new in new }
            return changes
        }

        changes.forEach { type, isActive in
            let repository = type.repositoryType.init(dependencies, language: language)
            if isActive {
                repository.setInitial()
            } else {
                repository.reset()
            }
        }

        continuation.yield(dependencies.stateClient.withLock(\.bundle))
    }

    private func updateSystemInfo() async {
        for type in SystemInfoType.allCases {
            let repository = type.repositoryType.init(dependencies, language: language)
            if dependencies.stateClient.withLock(\.activationState[type]) ?? false {
                await repository.update()
            } else {
                repository.reset()
            }
        }
        continuation.yield(dependencies.stateClient.withLock(\.bundle))
    }
}
