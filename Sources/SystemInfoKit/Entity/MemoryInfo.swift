public struct MemoryInfo: SystemInfo {
    public let type = SystemInfoType.memory
    public internal(set) var value = Double.zero
    public let icon = "memorychip"
    public internal(set) var pressureValue = Double.zero
    public internal(set) var appValue = Double.zero
    public internal(set) var wiredValue = Double.zero
    public internal(set) var compressedValue = Double.zero

    public var summary: String {
        String(localized: "memory\(value)", bundle: .module)
    }

    public var details: [String] {
        [
            String(localized: "memoryPressure\(pressureValue)", bundle: .module),
            String(localized: "memoryApp\(appValue)", bundle: .module),
            String(localized: "memoryWired\(wiredValue)", bundle: .module),
            String(localized: "memoryCompressed\(compressedValue)", bundle: .module)
        ]
    }
}

extension MemoryInfo {
    public static func createMock(
        value: Double,
        pressureValue: Double,
        appValue: Double,
        wiredValue: Double,
        compressedValue: Double
    ) -> MemoryInfo {
        MemoryInfo(
            value: value,
            pressureValue: pressureValue,
            appValue: appValue,
            wiredValue: wiredValue,
            compressedValue: compressedValue
        )
    }
}
