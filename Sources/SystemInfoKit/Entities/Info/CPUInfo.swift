import Foundation

public struct CPUInfo: SystemInfo {
    public let type = SystemInfoType.cpu
    public internal(set) var percentage: Percentage
    public internal(set) var system: Percentage
    public internal(set) var user: Percentage
    public internal(set) var idle: Percentage
    var language: Language

    public var icon: String { type.icon }

    public var summary: String {
        string(localized: "cpu\(String(describing: percentage))")
    }

    public var details: [String] {
        [
            string(localized: "cpuSystem\(String(describing: system))"),
            string(localized: "cpuUser\(String(describing: user))"),
            string(localized: "cpuIdle\(String(describing: idle))"),
        ]
    }

    init(
        percentage: Percentage = .zero,
        system: Percentage = .zero,
        user: Percentage = .zero,
        idle: Percentage = .zero,
        language: Language
    ) {
        self.percentage = percentage.localized(with: language)
        self.system = system.localized(with: language)
        self.user = user.localized(with: language)
        self.idle = idle.localized(with: language)
        self.language = language
    }

    public init(
        percentage: Percentage,
        system: Percentage,
        user: Percentage,
        idle: Percentage,
    ) {
        self.init(
            percentage: percentage,
            system: system,
            user: user,
            idle: idle,
            language: .automatic
        )
    }

    public static let zero = CPUInfo(language: .automatic)
}
