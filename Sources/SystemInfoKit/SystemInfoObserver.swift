import Foundation
import Combine
import os

public final class SystemInfoObserver: Sendable {
    public static func shared(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        SystemInfoObserver(monitorInterval: monitorInterval)
    }

    private let protectedActivationState = OSAllocatedUnfairLock<[SystemInfoType: Bool]>(
        initialState: [.cpu: true, .memory: true, .storage: true, .battery: true, .network: true]
    )

    private let monitorInterval: Double
    private let protectedCPURepository = OSAllocatedUnfairLock<CPURepository?>(initialState: nil)
    private let protectedMemoryRepository = OSAllocatedUnfairLock<MemoryRepository?>(initialState: nil)
    private let protectedStorageRepository = OSAllocatedUnfairLock<StorageRepository?>(initialState: nil)
    private let protectedBatteryRepository = OSAllocatedUnfairLock<BatteryRepository?>(initialState: nil)
    private let protectedNetworkRepository = OSAllocatedUnfairLock<NetworkRepository?>(initialState: nil)
    private let protectedTimer = OSAllocatedUnfairLock<AnyCancellable?>(initialState: nil)

    private let systemInfoSubject = CurrentValueSubject<SystemInfoBundle, Never>(.init())
    public var systemInfoStream: AsyncStream<SystemInfoBundle> {
        AsyncStream { continuation in
            let cancellable = systemInfoSubject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    private init(monitorInterval: Double = 5.0) {
        self.monitorInterval = monitorInterval
    }

    public func startMonitoring() {
        protectedCPURepository.withLock { $0 = .init() }
        protectedMemoryRepository.withLock { $0 = .init() }
        protectedStorageRepository.withLock { $0 = .init() }
        protectedBatteryRepository.withLock { $0 = .init() }
        protectedNetworkRepository.withLock { $0 = .init() }
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
        protectedCPURepository.withLock { $0 = nil }
        protectedMemoryRepository.withLock { $0 = nil }
        protectedStorageRepository.withLock { $0 = nil }
        protectedBatteryRepository.withLock { $0 = nil }
        protectedNetworkRepository.withLock { $0 = nil }
    }

    public func activate(types: [SystemInfoType]) {
        protectedActivationState.withLock { state in
            types.forEach { state[$0] = true }
        }
    }

    public func deactivate(types: [SystemInfoType]) {
        protectedActivationState.withLock { state in
            types.forEach { state[$0] = false }
        }
    }

    private func updateSystemInfo() {
        var systemInfo = SystemInfoBundle()
        let activationState = protectedActivationState.withLock(\.self)
        // CPU
        if activationState[.cpu] == true {
            systemInfo.cpuInfo = protectedCPURepository.withLock {
                $0?.update()
                return $0?.current
            }
        }
        // Memory
        if activationState[.memory] == true {
            systemInfo.memoryInfo = protectedMemoryRepository.withLock {
                $0?.update()
                return $0?.current
            }
        } else {
            protectedMemoryRepository.withLock { $0?.reset() }
        }
        // Storage
        if activationState[.storage] == true {
            systemInfo.storageInfo = protectedStorageRepository.withLock {
                $0?.update()
                return $0?.current
            }
        } else {
            protectedStorageRepository.withLock { $0?.reset() }
        }
        // Battery
        if activationState[.battery] == true {
            systemInfo.batteryInfo = protectedBatteryRepository.withLock {
                $0?.update()
                return $0?.current
            }
        } else {
            protectedBatteryRepository.withLock { $0?.reset() }
        }
        // Network
        if activationState[.network] == true {
            systemInfo.networkInfo = protectedNetworkRepository.withLock {
                $0?.update(interval: monitorInterval)
                return $0?.current
            }
        } else {
            protectedNetworkRepository.withLock { $0?.reset() }
        }
        systemInfoSubject.send(systemInfo)
    }
}

extension AnyCancellable: @retroactive @unchecked Sendable {}
extension CurrentValueSubject: @retroactive @unchecked Sendable {}
