import Foundation
import Combine

public final class SystemInfoObserver {
    public static func shared(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        SystemInfoObserver(
            monitorInterval: monitorInterval,
            cpuType: CPURepositoryImpl.self,
            memoryType: MemoryRepositoryImpl.self,
            storageType: StorageRepositoryImpl.self,
            batteryType: BatteryRepositoryImpl.self,
            networkType: NetworkRepositoryImpl.self
        )
    }

    public static func sharedMock(monitorInterval: Double = 5.0) -> SystemInfoObserver {
        SystemInfoObserver(
            monitorInterval: monitorInterval,
            cpuType: CPURepositoryMock.self,
            memoryType: MemoryRepositoryMock.self,
            storageType: StorageRepositoryMock.self,
            batteryType: BatteryRepositoryMock.self,
            networkType: NetworkRepositoryMock.self
        )
    }

    public var activatedCPU = true
    public var activatedMemory = true
    public var activatedStorage = true
    public var activatedBattery = true
    public var activatedNetwork = true

    private let cpuType: any CPURepository.Type
    private var cpuRepository: (any CPURepository)?
    private let memoryType: any MemoryRepository.Type
    private var memoryRepository: (any MemoryRepository)?
    private let storageType: any StorageRepository.Type
    private var storageRepository: (any StorageRepository)?
    private let batteryType: any BatteryRepository.Type
    private var batteryRepository: (any BatteryRepository)?
    private let networkType: any NetworkRepository.Type
    private var networkRepository: (any NetworkRepository)?
    private var timerCancellables: AnyCancellable?
    private let monitorInterval: Double

    private let systemInfoSubject = CurrentValueSubject<SystemInfoBundle, Never>(.init())
    public var systemInfoPublisher: AnyPublisher<SystemInfoBundle, Never> {
        systemInfoSubject.eraseToAnyPublisher()
    }

    private init(
        monitorInterval: Double = 5.0,
        cpuType: any CPURepository.Type,
        memoryType: any MemoryRepository.Type,
        storageType: any StorageRepository.Type,
        batteryType: any BatteryRepository.Type,
        networkType: any NetworkRepository.Type
    ) {
        self.monitorInterval = monitorInterval
        self.cpuType = cpuType
        self.memoryType = memoryType
        self.storageType = storageType
        self.batteryType = batteryType
        self.networkType = networkType
    }

    public func startMonitoring() {
        cpuRepository = cpuType.init()
        memoryRepository = memoryType.init()
        storageRepository = storageType.init()
        batteryRepository = batteryType.init()
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
        storageRepository = nil
        batteryRepository = nil
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
        // Storage
        if activatedStorage {
            storageRepository?.update()
            systemInfo.storageInfo = storageRepository?.current
        } else {
            storageRepository?.reset()
        }
        // Battery
        if activatedBattery {
            batteryRepository?.update()
            systemInfo.batteryInfo = batteryRepository?.current
        } else {
            batteryRepository?.reset()
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
