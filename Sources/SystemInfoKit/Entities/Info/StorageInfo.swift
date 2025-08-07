import Foundation

public struct StorageInfo: SystemInfo {
    public let type = SystemInfoType.storage
    public internal(set) var percentage = Percentage.zero
    public let icon = "internaldrive"
    public internal(set) var total = ByteData.zero
    public internal(set) var available = ByteData.zero
    public internal(set) var used = ByteData.zero

    public var summary: String {
        String(localized: "storage\(percentage.description)", bundle: .module)
    }

    public var details: [String] {
        if percentage.value == .zero {
            ["--- / ---"]
        } else {
            ["\(used) / \(total)"]
        }
    }
}

extension StorageInfo {
    public static func createMock(
        percentage: Percentage,
        total: ByteData,
        available: ByteData,
        used: ByteData
    ) -> StorageInfo {
        StorageInfo(
            percentage: percentage,
            total: total,
            available: available,
            used: used
        )
    }

    public static let zero = StorageInfo()
}
