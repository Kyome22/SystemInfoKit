public struct BatteryInfo: SystemInfo {
    public let type = SystemInfoType.battery
    public internal(set) var value = Double.zero
    public let installed: Bool
    public internal(set) var isCharging = false
    private var adapterName: String?
    private var healthValue = Double.zero
    private var maxCapacityValue = Double.zero
    private var cycleValue = Int.zero
    private var temperatureValue = Double.zero

    public var icon: String {
        let suffix = if #available(macOS 14.0, *) { "percent" } else { "" }
        switch (installed, isCharging) {
        case (true, true):
            return "battery.100\(suffix).bolt"
        case (true, false):
            return switch value {
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
        if installed {
            String(localized: "battery\(value)", bundle: .module)
        } else {
            String(localized: "batteryIsNotInstalled", bundle: .module)
        }
    }

    private var powerSourceValue: String {
        if isCharging {
            adapterName ?? String(localized: "batteryUnknown", bundle: .module)
        } else {
            String(localized: "battery", bundle: .module)
        }
    }

    private var condition: String {
        String(localized: "batteryCondition\(healthValue)", bundle: .module)
    }

    private var maxCapacity: String {
        String(localized: "batteryMaxCapacity\(maxCapacityValue)", bundle: .module)
    }

    private var conditionOrMaxCapacity: String {
#if arch(x86_64) // Intel chip
        condition
#elseif arch(arm64) // Apple Silicon chip
        maxCapacity
#endif
    }

    public var details: [String] {
        [
            String(localized: "batteryPowerSource\(powerSourceValue)", bundle: .module),
            conditionOrMaxCapacity,
            String(localized: "batteryCycle\(cycleValue)", bundle: .module),
            String(localized: "batteryTemperature\(temperatureValue)", bundle: .module)
        ]
    }

    init(installed: Bool = false) {
        self.installed = installed
    }

    mutating func setIsCharging(_ value: Bool) {
        isCharging = value
    }

    mutating func setAdapterName(_ value: String) {
        adapterName = value
    }

    mutating func setHealthValue(_ value: Double) {
        healthValue = value
    }

    mutating func setMaxCapacityValue(_ value: Double) {
        maxCapacityValue = value
    }

    mutating func setCycleValue(_ value: Int) {
        cycleValue = value
    }

    mutating func setTemperatureValue(_ value: Double) {
        temperatureValue = value
    }
}
