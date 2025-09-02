public struct SystemInfoBundle: Sendable {
    public var cpuInfo: CPUInfo?
    public var memoryInfo: MemoryInfo?
    public var storageInfo: StorageInfo?
    public var batteryInfo: BatteryInfo?
    public var networkInfo: NetworkInfo?

    public init() {}
}

extension SystemInfoBundle: CustomStringConvertible {
    public var description: String {
        let array = [
            cpuInfo?.description,
            memoryInfo?.description,
            storageInfo?.description,
            batteryInfo?.description,
            networkInfo?.description,
        ]
        return array.compactMap(\.self).joined(separator: "\n")
    }
}
