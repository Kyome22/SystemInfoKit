import Foundation

#if os(macOS)
public struct BatteryInfo: SystemInfo {
    public let type = SystemInfoType.battery
    public internal(set) var percentage: Percentage
    public internal(set) var isInstalled: Bool
    public internal(set) var isCharging: Bool
    public internal(set) var adapterName: String?
    public internal(set) var maxCapacity: Percentage
    public internal(set) var cycleCount: Int
    public internal(set) var temperature: Temperature
    var language: Language

    public var icon: String {
        let suffix = if #available(macOS 14.0, *) { "percent" } else { "" }
        return switch (isInstalled, isCharging) {
        case (true, true):
            "battery.100\(suffix).bolt"
        case (true, false):
            "battery.\(percentage.batteryRoughValue)\(suffix)"
        case (false, _):
            "powerplug"
        }
    }

    public var summary: String {
        if isInstalled {
            string(localized: "battery\(String(describing: percentage))")
        } else {
            string(localized: "batteryIsNotInstalled")
        }
    }

    private var powerSource: String {
        if isCharging {
            adapterName ?? string(localized: "batteryUnknown")
        } else {
            string(localized: "battery")
        }
    }

    public var details: [String] {
        [
            string(localized: "batteryPowerSource\(powerSource)"),
            string(localized: "batteryMaxCapacity\(String(describing: maxCapacity))"),
            string(localized: "batteryCycle\(cycleCount)"),
            string(localized: "batteryTemperature\(String(describing: temperature))"),
        ]
    }

    public var description: String {
        isInstalled ? _description : summary
    }

    init(
        percentage: Percentage = .zero,
        isInstalled: Bool = false,
        isCharging: Bool = false,
        adapterName: String? = nil,
        maxCapacity: Percentage = .zero,
        cycleCount: Int = .zero,
        temperature: Temperature = .zero,
        language: Language
    ) {
        self.percentage = percentage.localized(with: language)
        self.isInstalled = isInstalled
        self.isCharging = isCharging
        self.adapterName = adapterName
        self.maxCapacity = maxCapacity.localized(with: language)
        self.cycleCount = cycleCount
        self.temperature = temperature.localized(with: language)
        self.language = language
    }

    public init(
        percentage: Percentage,
        isInstalled: Bool,
        isCharging: Bool,
        adapterName: String?,
        maxCapacity: Percentage,
        cycleCount: Int,
        temperature: Temperature,
    ) {
        self.init(
            percentage: percentage,
            isInstalled: isInstalled,
            isCharging: isCharging,
            adapterName: adapterName,
            maxCapacity: maxCapacity,
            cycleCount: cycleCount,
            temperature: temperature,
            language: .automatic
        )
    }

    public static let zero = BatteryInfo(language: .automatic)
}
#elseif os(iOS)
public struct BatteryInfo: SystemInfo {
    public let type = SystemInfoType.battery
    public internal(set) var percentage: Percentage
    public internal(set) var isCharging: Bool
    var language: Language

    public var icon: String {
        return switch isCharging {
        case true:
            "battery.100percent.bolt"
        case false:
            "battery.\(percentage.batteryRoughValue)percent"
        }
    }

    public var summary: String {
        string(localized: "battery\(String(describing: percentage))")
    }

    public let details = [String]()

    init(
        percentage: Percentage = .zero,
        isCharging: Bool = false,
        language: Language
    ) {
        self.percentage = percentage.localized(with: language)
        self.isCharging = isCharging
        self.language = language
    }

    public init(
        percentage: Percentage,
        isCharging: Bool
    ) {
        self.init(
            percentage: percentage,
            isCharging: isCharging,
            language: .automatic
        )
    }

    public static let zero = BatteryInfo(language: .automatic)
}
#endif

extension Percentage {
    var batteryRoughValue: Int {
        Int(min(max(value + 5, 0), 100) / 25) * 25
    }
}
