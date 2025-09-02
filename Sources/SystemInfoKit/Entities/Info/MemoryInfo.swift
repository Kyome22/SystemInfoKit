public struct MemoryInfo: SystemInfo {
    public let type = SystemInfoType.memory
    public internal(set) var percentage = Percentage.zero
    public let icon = "memorychip"
    public internal(set) var pressure = Percentage.zero
    public internal(set) var app = ByteData.zero
    public internal(set) var wired = ByteData.zero
    public internal(set) var compressed = ByteData.zero

    public var summary: String {
        String(localized: "memory\(String(describing: percentage))", bundle: .module)
    }

    public var details: [String] {
        [
            String(localized: "memoryPressure\(String(describing: pressure))", bundle: .module),
            String(localized: "memoryApp\(String(describing: app))", bundle: .module),
            String(localized: "memoryWired\(String(describing: wired))", bundle: .module),
            String(localized: "memoryCompressed\(String(describing: compressed))", bundle: .module)
        ]
    }
}

extension MemoryInfo {
    public static func createMock(
        percentage: Percentage,
        pressure: Percentage,
        app: ByteData,
        wired: ByteData,
        compressed: ByteData
    ) -> MemoryInfo {
        MemoryInfo(
            percentage: percentage,
            pressure: pressure,
            app: app,
            wired: wired,
            compressed: compressed
        )
    }

    public static let zero = MemoryInfo()
}
