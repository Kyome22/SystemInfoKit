public struct CPUInfo: SystemInfo {
    public let type = SystemInfoType.cpu
    public internal(set) var percentage = Percentage.zero
    public let icon = "cpu"
    public internal(set) var system = Percentage.zero
    public internal(set) var user = Percentage.zero
    public internal(set) var idle = Percentage.zero

    public var summary: String {
        String(localized: "cpu\(String(describing: percentage))", bundle: .module)
    }

    public var details: [String] {
        [
            String(localized: "cpuSystem\(String(describing: system))", bundle: .module),
            String(localized: "cpuUser\(String(describing: user))", bundle: .module),
            String(localized: "cpuIdle\(String(describing: idle))", bundle: .module)
        ]
    }
}

extension CPUInfo {
    public static func createMock(
        percentage: Percentage,
        system: Percentage,
        user: Percentage,
        idle: Percentage
    ) -> CPUInfo {
        CPUInfo(
            percentage: percentage,
            system: system,
            user: user,
            idle: idle
        )
    }

    public static let zero = CPUInfo()
}
