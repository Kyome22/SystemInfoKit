import Foundation
import Combine

public final class SystemInfoObserver {
    public static func shared(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        return SystemInfoObserver(
            monitorInterval: monitorInterval,
            cpuType: CPURepositoryImpl.self,
            memoryType: MemoryRepositoryImpl.self,
            batteryType: BatteryRepositoryImpl.self,
            storageType: StorageRepositoryImpl.self,
            networkType: NetworkRepositoryImpl.self
        )
    }

    public static func sharedMock(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        return SystemInfoObserver(
            monitorInterval: monitorInterval,
            cpuType: CPURepositoryMock.self,
            memoryType: MemoryRepositoryMock.self,
            batteryType: BatteryRepositoryMock.self,
            storageType: StorageRepositoryMock.self,
            networkType: NetworkRepositoryMock.self
        )
    }

    public var activatedCPU: Bool = true
    public var activatedMemory: Bool = true
    public var activatedBattery: Bool = true
    public var activatedStorage: Bool = true
    public var activatedNetwork: Bool = true

    private let cpuType: CPURepository.Type
    private var cpuRepository: (any CPURepository)?
    private let memoryType: MemoryRepository.Type
    private var memoryRepository: (any MemoryRepository)?
    private let batteryType: BatteryRepository.Type
    private var batteryRepository: (any BatteryRepository)?
    private let storageType: StorageRepository.Type
    private var storageRepository: (any StorageRepository)?
    private let networkType: NetworkRepository.Type
    private var networkRepository: (any NetworkRepository)?
    private var timerCancellables: AnyCancellable?
    private let monitorInterval: Double

    private let systemInfoSubject = CurrentValueSubject<SystemInfoBundle, Never>(.init())
    public var systemInfoPublisher: AnyPublisher<SystemInfoBundle, Never> {
        systemInfoSubject.eraseToAnyPublisher()
    }

    private init(
        monitorInterval: Double = 5.0,
        cpuType: CPURepository.Type,
        memoryType: MemoryRepository.Type,
        batteryType: BatteryRepository.Type,
        storageType: StorageRepository.Type,
        networkType: NetworkRepository.Type
    ) {
        self.monitorInterval = monitorInterval
        self.cpuType = cpuType
        self.memoryType = memoryType
        self.batteryType = batteryType
        self.storageType = storageType
        self.networkType = networkType
    }

    public func startMonitoring() {
        cpuRepository = cpuType.init()
        memoryRepository = memoryType.init()
        batteryRepository = batteryType.init()
        storageRepository = storageType.init()
        networkRepository = networkType.init()
        timerCancellables = Timer
            .publish(every: monitorInterval, on: RunLoop.main, in: .common)
            .autoconnect()
            .prepend(Date())
            .sink { [weak self] _ in
                self?.updateSystemInfo()
            }
    }

    public func stopMonitoring() {
        timerCancellables?.cancel()
        timerCancellables = nil
        cpuRepository = nil
        memoryRepository = nil
        batteryRepository = nil
        storageRepository = nil
        networkRepository = nil
    }

    private func updateSystemInfo() {
        var systemInfo = SystemInfoBundle()
        // CPU
        if activatedCPU {
            cpuRepository?.update()
            systemInfo.cpuInfo = cpuRepository?.current
        }
        // Memory
        if activatedMemory {
            memoryRepository?.update()
            systemInfo.memoryInfo = memoryRepository?.current
        } else {
            memoryRepository?.reset()
        }
        // Battery
        if activatedBattery {
            batteryRepository?.update()
            systemInfo.batteryInfo = batteryRepository?.current
        } else {
            batteryRepository?.reset()
        }
        // Storage
        if activatedStorage {
            storageRepository?.update()
            systemInfo.storageInfo = storageRepository?.current
        } else {
            storageRepository?.reset()
        }
        // Network
        if activatedNetwork {
            networkRepository?.update(interval: monitorInterval)
            systemInfo.networkInfo = networkRepository?.current
        } else {
            networkRepository?.reset()
        }
        systemInfoSubject.send(systemInfo)
    }
}
