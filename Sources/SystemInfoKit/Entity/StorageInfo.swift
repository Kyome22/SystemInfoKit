import Foundation

public struct ByteData: CustomStringConvertible {
    public internal(set) var value: Double
    public internal(set) var unit: String

    public var description: String {
        return String(format: "%.2f %@", value, unit)
    }
}

public struct StorageInfo: SystemInfo {
    public let type: SystemInfoType = .storage
    public internal(set) var value: Double = .zero
    public let icon: String = "internaldrive"
    public private(set) var totalValue = ByteData(value: .zero, unit: "GB")
    public private(set) var availableValue = ByteData(value: .zero, unit: "GB")
    public private(set) var usedValue = ByteData(value: .zero, unit: "GB")

    public var summary: String {
        return String(localized: "storage\(value)", bundle: .module)
    }

    public var details: [String] {
        if value == .zero {
            return ["--- GB / --- GB"]
        } else {
            return ["\(usedValue) / \(totalValue)"]
        }
    }

    init() {}

    // support french style 3,14 → 3.14
    private func convertByteData(_ byteCount: Int64) -> ByteData {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .decimal
        let array = fmt.string(fromByteCount: byteCount)
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: .whitespaces)
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
