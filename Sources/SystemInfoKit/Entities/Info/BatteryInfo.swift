import Foundation

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

    private var roughValue: Int {
        Int(min(max(percentage.value + 5, 0), 100) / 25) * 25
    }

    public var icon: String {
        let suffix = if #available(macOS 14.0, *) { "percent" } else { "" }
        return switch (isInstalled, isCharging) {
        case (true, true):
            "battery.100\(suffix).bolt"
        case (true, false):
            "battery.\(roughValue)\(suffix)"
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
        isInstalled: Bool = true,
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
