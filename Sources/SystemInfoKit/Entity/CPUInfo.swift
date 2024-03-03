public struct CPUInfo: SystemInfo {
    public let type: SystemInfoType = .cpu
    public internal(set) var value: Double = .zero
    public let icon: String = "cpu"
    private var systemValue: Double = .zero
    private var userValue: Double = .zero
    private var idleValue: Double = .zero

    public var summary: String {
        return String(localized: "cpu\(value)", bundle: .module)
    }

    public var details: [String] {
        return [
            String(localized: "cpuSystem\(systemValue)", bundle: .module),
            String(localized: "cpuUser\(userValue)", bundle: .module),
            String(localized: "cpuIdle\(idleValue)", bundle: .module)
        ]
    }

    init() {}

    mutating func setSystemValue(_ value: Double) {
        self.systemValue = value
    }

    mutating func setUserValue(_ value: Double) {
        self.userValue = value
    }

    mutating func setIdleValue(_ value: Double) {
        self.idleValue = value
    }
}
