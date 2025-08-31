@preconcurrency import Combine
import Foundation
import os

public final class SystemInfoObserver: Sendable {
    public static func shared(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        SystemInfoObserver(monitorInterval: monitorInterval)
    }

    private let systemInfoStateClient: SystemInfoStateClient
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
        systemInfoStateClient: SystemInfoStateClient = .liveValue,
        monitorInterval: Double
    ) {
        self.systemInfoStateClient = systemInfoStateClient
        systemInfoStateClient.withLock { $0.interval = max(monitorInterval, 1.0) }
    }

    public func startMonitoring() {
        let interval = systemInfoStateClient.withLock(\.interval)
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
        systemInfoStateClient.withLock { state in
            requests.forEach { state.activationState[$0.key] = $0.value }
        }
    }

    private func updateSystemInfo() {
        let activationState = systemInfoStateClient.withLock(\.activationState)
        // CPU
        let cpuRepository = CPURepository(systemInfoStateClient)
        if activationState[.cpu] == true {
            cpuRepository.update()
        } else {
            cpuRepository.reset()
        }
        // Memory
        let memoryRepository = MemoryRepository(systemInfoStateClient)
        if activationState[.memory] == true {
            memoryRepository.update()
        } else {
            memoryRepository.reset()
        }
        // Storage
        let storageRepository = StorageRepository(systemInfoStateClient)
        if activationState[.storage] == true {
            storageRepository.update()
        } else {
            storageRepository.reset()
        }
        // Battery
        let batteryRepository = BatteryRepository(systemInfoStateClient)
        if activationState[.battery] == true {
            batteryRepository.update()
        } else {
            batteryRepository.reset()
        }
        // Network
        let networkRepository = NetworkRepository(systemInfoStateClient)
        if activationState[.network] == true {
            networkRepository.update()
        } else {
            networkRepository.reset()
        }
        // Send SystemInfoBundle
        systemInfoSubject.send(systemInfoStateClient.withLock(\.bundle))
    }
}
