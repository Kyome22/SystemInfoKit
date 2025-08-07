import Foundation

public struct ByteData: Sendable, CustomStringConvertible {
    public internal(set) var byteCount: Int64
    public internal(set) var value: Double
    public internal(set) var unit: String

    public var description: String {
        String(format: "%4.1f %@", locale: .current, value, unit)
    }

    public init(byteCount: Int64) {
        self.byteCount = byteCount
        let style = ByteCountFormatStyle(
            style: .decimal,
            allowedUnits: .kb.union(.mb).union(.gb).union(.tb).union(.pb),
            spellsOutZero: false,
            locale: .current
        )
        let array = style.format(byteCount).components(separatedBy: .whitespaces)
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        self.value = formatter.number(from: array[0])?.doubleValue ?? .zero
        self.unit = array[1]
    }

    public static let zero = ByteData(byteCount: .zero)
}
