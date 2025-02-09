import Foundation

public struct ByteData: Sendable, CustomStringConvertible {
    public internal(set) var value: Double
    public internal(set) var unit: String

    public var description: String {
        String(format: "%.2f %@", value, unit)
    }
}

public struct StorageInfo: SystemInfo {
    public let type = SystemInfoType.storage
    public internal(set) var value = Double.zero
    public let icon = "internaldrive"
    public private(set) var totalValue = ByteData(value: .zero, unit: "GB")
    public private(set) var availableValue = ByteData(value: .zero, unit: "GB")
    public private(set) var usedValue = ByteData(value: .zero, unit: "GB")

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

    init() {}

    private func convertByteData(_ byteCount: Int64) -> ByteData {
        let style = ByteCountFormatStyle(
            style: .decimal,
            allowedUnits: [.kb, .mb, .gb, .tb, .pb, .eb],
            locale: Locale(identifier: "en_US")
        )
        let array = style.format(byteCount).components(separatedBy: .whitespaces)
        return ByteData(value: Double(array[0]) ?? 0.0, unit: array[1])
    }

    mutating func setTotalValue(byteCount: Int64) {
        totalValue = convertByteData(byteCount)
    }

    mutating func setAvailableValue(byteCount: Int64) {
        availableValue = convertByteData(byteCount)
    }

    mutating func setUsedValue(byteCount: Int64) {
        usedValue = convertByteData(byteCount)
    }
}
