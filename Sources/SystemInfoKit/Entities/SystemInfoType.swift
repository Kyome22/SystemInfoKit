public enum SystemInfoType: Sendable, CaseIterable {
    case cpu
    case memory
    case storage
    case battery
    case network

    var repositoryType: any SystemRepository.Type {
        switch self {
        case .cpu: CPURepository.self
        case .memory: MemoryRepository.self
        case .storage: StorageRepository.self
        case .battery: BatteryRepository.self
        case .network: NetworkRepository.self
        }
    }
}
