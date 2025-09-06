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

    var icon: String {
        switch self {
        case .cpu: 
            "cpu"
        case .memory: 
            "memorychip"
        case .storage: 
            "internaldrive"
        case .battery:
            if #available(macOS 14.0, *) {
                "battery.100percent"
            } else {
                "battery.100"
            }
        case .network: 
            "network"
        }
    }
}
