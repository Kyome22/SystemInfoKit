import Foundation

public struct ByteData: Sendable, CustomStringConvertible {
    public internal(set) var byteCount: Int64
    public internal(set) var value: Double
    public internal(set) var unit: String
    var locale: Locale

    public var description: String {
        String(format: "%4.1f %@", locale: locale, value, unit)
    }

    public init(byteCount: Int64, locale: Locale = .current) {
        self.byteCount = byteCount
        self.locale = locale
        let formatStyle = ByteCountFormatStyle(
            style: .decimal,
            allowedUnits: .kb.union(.mb).union(.gb).union(.tb).union(.pb),
            spellsOutZero: false,
            locale: locale
        )
        guard let (count, unit) = formatStyle.format(byteCount).separete() else {
            self.value = .zero
            self.unit = ""
            return
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        self.value = formatter.number(from: count)?.doubleValue ?? .zero
        self.unit = unit
    }

    public static let zero = ByteData(byteCount: .zero)
}
