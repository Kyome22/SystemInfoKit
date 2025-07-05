public struct CPUInfo: SystemInfo {
    public let type = SystemInfoType.cpu
    public internal(set) var value = Double.zero
    public let icon = "cpu"
    public internal(set) var systemValue = Double.zero
    public internal(set) var userValue = Double.zero
    public internal(set) var idleValue = Double.zero

    public var summary: String {
        String(localized: "cpu\(value)", bundle: .module)
    }

    public var details: [String] {
        [
            String(localized: "cpuSystem\(systemValue)", bundle: .module),
            String(localized: "cpuUser\(userValue)", bundle: .module),
            String(localized: "cpuIdle\(idleValue)", bundle: .module)
        ]
    }
}

extension CPUInfo {
    public static func createMock(
        value: Double,
        systemValue: Double,
        userValue: Double,
        idleValue: Double
    ) -> CPUInfo {
        CPUInfo(
            value: value,
            systemValue: systemValue,
            userValue: userValue,
            idleValue: idleValue
        )
    }

    public static let zero = CPUInfo()
}
