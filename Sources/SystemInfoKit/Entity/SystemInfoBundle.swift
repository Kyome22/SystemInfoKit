public struct SystemInfoBundle {
    public var cpuInfo: CPUInfo?
    public var memoryInfo: MemoryInfo?
    public var storageInfo: StorageInfo?
    public var batteryInfo: BatteryInfo?
    public var networkInfo: NetworkInfo?

    public init() {}
}

extension SystemInfoBundle: CustomStringConvertible {
    public var description: String {
        var array = [String]()
        if let description = cpuInfo?.description {
            array.append(description)
        }
        if let description = memoryInfo?.description {
            array.append(description)
        }
        if let description = storageInfo?.description {
            array.append(description)
        }
        if let description = batteryInfo?.description {
            array.append(description)
        }
        if let description = networkInfo?.description {
            array.append(description)
        }
        return array.joined(separator: "\n")
    }
}
