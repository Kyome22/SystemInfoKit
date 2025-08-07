public struct BatteryInfo: SystemInfo {
    public let type = SystemInfoType.battery
    public internal(set) var percentage = Percentage.zero
    public let isInstalled: Bool
    public internal(set) var isCharging = false
    public internal(set) var adapterName: String?
    public internal(set) var health = CapacityHealth.maxCapacity(.zero)
    public internal(set) var cycleCount = Int.zero
    public internal(set) var temperature = Double.zero

    public var icon: String {
        let suffix = if #available(macOS 14.0, *) { "percent" } else { "" }
        switch (isInstalled, isCharging) {
        case (true, true):
            return "battery.100\(suffix).bolt"
        case (true, false):
            return switch percentage.value {
            case 0 ..< 20:  "battery.0\(suffix)"
            case 20 ..< 45: "battery.25\(suffix)"
            case 45 ..< 70: "battery.50\(suffix)"
            case 70 ..< 95: "battery.75\(suffix)"
            default:        "battery.100\(suffix)"
            }
        case (false, _):
            return "powerplug"
        }
    }

    public var summary: String {
        if isInstalled {
            String(localized: "battery\(percentage.description)", bundle: .module)
        } else {
            String(localized: "batteryIsNotInstalled", bundle: .module)
        }
    }

    private var powerSource: String {
        if isCharging {
            adapterName ?? String(localized: "batteryUnknown", bundle: .module)
        } else {
            String(localized: "battery", bundle: .module)
        }
    }

    private var conditionOrMaxCapacity: String {
        switch health {
        case let .maxCapacity(percentage):
            String(localized: "batteryCondition\(percentage.description)", bundle: .module)
        case let .condition(percentage):
            String(localized: "batteryMaxCapacity\(percentage.description)", bundle: .module)
        }
    }

    public var details: [String] {
        [
            String(localized: "batteryPowerSource\(powerSource)", bundle: .module),
            conditionOrMaxCapacity,
            String(localized: "batteryCycle\(cycleCount)", bundle: .module),
            String(localized: "batteryTemperature\(temperature)", bundle: .module)
        ]
    }
}

extension BatteryInfo {
    public static func createMock(
        percentage: Percentage,
        isInstalled: Bool,
        isCharging: Bool,
        adapterName: String?,
        health: CapacityHealth,
        cycleCount: Int,
        temperature: Double
    ) -> BatteryInfo {
        BatteryInfo(
            percentage: percentage,
            isInstalled: isInstalled,
            isCharging: isCharging,
            adapterName: adapterName,
            health: health,
            cycleCount: cycleCount,
            temperature: temperature
        )
    }

    public static let zero = BatteryInfo(isInstalled: true)
}
