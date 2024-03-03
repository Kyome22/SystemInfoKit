public struct MemoryInfo: SystemInfo {
    public let type: SystemInfoType = .memory
    public internal(set) var value: Double = .zero
    public let icon: String = "memorychip"
    private var pressureValue: Double = .zero
    private var appValue: Double = .zero
    private var wiredValue: Double = .zero
    private var compressedValue: Double = .zero

    public var summary: String {
        return String(localized: "memory\(value)", bundle: .module)
    }

    public var details: [String] {
        return [
            String(localized: "memoryPressure\(pressureValue)", bundle: .module),
            String(localized: "memoryApp\(appValue)", bundle: .module),
            String(localized: "memoryWired\(wiredValue)", bundle: .module),
            String(localized: "memoryCompressed\(compressedValue)", bundle: .module)
        ]
    }

    init() {}

    mutating func setPressureValue(_ value: Double) {
        self.pressureValue = value
    }

    mutating func setAppValue(_ value: Double) {
        self.appValue = value
    }

    mutating func setWiredValue(_ value: Double) {
        self.wiredValue = value
    }

    mutating func setCompressedValue(_ value: Double) {
        self.compressedValue = value
    }
}
