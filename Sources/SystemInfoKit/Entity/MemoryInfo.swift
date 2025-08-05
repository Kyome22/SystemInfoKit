public struct MemoryInfo: SystemInfo {
    public let type = SystemInfoType.memory
    public internal(set) var value = Double.zero
    public let icon = "memorychip"
    public internal(set) var pressureValue = Double.zero
    public internal(set) var appValue = ByteData.zero
    public internal(set) var wiredValue = ByteData.zero
    public internal(set) var compressedValue = ByteData.zero

    public var summary: String {
        String(localized: "memory\(value)", bundle: .module)
    }

    public var details: [String] {
        [
            String(localized: "memoryPressure\(pressureValue)", bundle: .module),
            String(localized: "memoryApp\(appValue.description)", bundle: .module),
            String(localized: "memoryWired\(wiredValue.description)", bundle: .module),
            String(localized: "memoryCompressed\(compressedValue.description)", bundle: .module)
        ]
    }
}

extension MemoryInfo {
    public static func createMock(
        value: Double,
        pressureValue: Double,
        appValue: ByteData,
        wiredValue: ByteData,
        compressedValue: ByteData
    ) -> MemoryInfo {
        MemoryInfo(
            value: value,
            pressureValue: pressureValue,
            appValue: appValue,
            wiredValue: wiredValue,
            compressedValue: compressedValue
        )
    }

    public static let zero = MemoryInfo()
}
