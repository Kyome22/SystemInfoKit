import Foundation

public struct ByteData: Sendable, CustomStringConvertible {
    public internal(set) var value = Double.zero
    public internal(set) var unit = "GB"

    public var description: String {
        String(format: "%.2f %@", value, unit)
    }

    public static func createMock(value: Double, unit: String) -> ByteData {
        ByteData(value: value, unit: unit)
    }
}

public struct StorageInfo: SystemInfo {
    public let type = SystemInfoType.storage
    public internal(set) var value = Double.zero
    public let icon = "internaldrive"
    public internal(set) var totalValue = ByteData()
    public internal(set) var availableValue = ByteData()
    public internal(set) var usedValue = ByteData()

    public var summary: String {
        String(localized: "storage\(value)", bundle: .module)
    }

    public var details: [String] {
        if value == .zero {
            ["--- GB / --- GB"]
        } else {
            ["\(usedValue) / \(totalValue)"]
        }
    }

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
}
