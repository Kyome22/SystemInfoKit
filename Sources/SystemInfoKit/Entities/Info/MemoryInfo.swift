import Foundation

public struct MemoryInfo: SystemInfo {
    public let type = SystemInfoType.memory
    public internal(set) var percentage: Percentage
    public internal(set) var pressure: Percentage
    public internal(set) var app: ByteData
    public internal(set) var wired: ByteData
    public internal(set) var compressed: ByteData
    var language: Language

    public var icon: String { type.icon }

    public var summary: String {
        string(localized: "memory\(String(describing: percentage))")
    }

    public var details: [String] {
        [
            string(localized: "memoryPressure\(String(describing: pressure))"),
            string(localized: "memoryApp\(String(describing: app))"),
            string(localized: "memoryWired\(String(describing: wired))"),
            string(localized: "memoryCompressed\(String(describing: compressed))"),
        ]
    }

    init(
        percentage: Percentage = .zero,
        pressure: Percentage = .zero,
        app: ByteData = .zero,
        wired: ByteData = .zero,
        compressed: ByteData = .zero,
        language: Language
    ) {
        self.percentage = percentage.localized(with: language)
        self.pressure = pressure.localized(with: language)
        self.app = app.localized(with: language)
        self.wired = wired.localized(with: language)
        self.compressed = compressed.localized(with: language)
        self.language = language
    }

    public init(
        percentage: Percentage,
        pressure: Percentage,
        app: ByteData,
        wired: ByteData,
        compressed: ByteData
    ) {
        self.init(
            percentage: percentage,
            pressure: pressure,
            app: app,
            wired: wired,
            compressed: compressed,
            language: .automatic
        )
    }

    public static let zero = MemoryInfo(language: .automatic)
}
