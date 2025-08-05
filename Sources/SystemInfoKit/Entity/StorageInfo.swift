import Foundation

public struct StorageInfo: SystemInfo {
    public let type = SystemInfoType.storage
    public internal(set) var value = Double.zero
    public let icon = "internaldrive"
    public internal(set) var totalValue = ByteData.zero
    public internal(set) var availableValue = ByteData.zero
    public internal(set) var usedValue = ByteData.zero

    public var summary: String {
        String(localized: "storage\(value)", bundle: .module)
    }

    public var details: [String] {
        if value == .zero {
            ["--- / ---"]
        } else {
            ["\(usedValue) / \(totalValue)"]
        }
    }
}

extension StorageInfo {
    public static func createMock(
        value: Double,
        totalValue: ByteData,
        availableValue: ByteData,
        usedValue: ByteData
    ) -> StorageInfo {
        StorageInfo(
            value: value,
            totalValue: totalValue,
            availableValue: availableValue,
            usedValue: usedValue
        )
    }

    public static let zero = StorageInfo()
}
