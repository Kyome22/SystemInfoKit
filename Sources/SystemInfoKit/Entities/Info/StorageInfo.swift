import Foundation

public struct StorageInfo: SystemInfo {
    public let type = SystemInfoType.storage
    public internal(set) var percentage: Percentage
    public internal(set) var total: ByteData
    public internal(set) var available: ByteData
    public internal(set) var used: ByteData
    var language: Language

    public var icon: String { type.icon }

    public var summary: String {
        string(localized: "storage\(String(describing: percentage))")
    }

    public var details: [String] {
        if percentage.value == .zero {
            ["--- / ---"]
        } else {
            ["\(used) / \(total)"]
        }
    }

    init(
        percentage: Percentage = .zero,
        total: ByteData = .zero,
        available: ByteData = .zero,
        used: ByteData = .zero,
        language: Language
    ) {
        self.percentage = percentage.localized(with: language)
        self.total = total.localized(with: language)
        self.available = available.localized(with: language)
        self.used = used.localized(with: language)
        self.language = language
    }

    public init(
        percentage: Percentage,
        total: ByteData,
        available: ByteData,
        used: ByteData
    ) {
        self.init(
            percentage: percentage,
            total: total,
            available: available,
            used: used,
            language: .automatic
        )
    }

    public static let zero = StorageInfo(language: .automatic)
}
