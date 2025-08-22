import Foundation

public struct Percentage: Sendable, CustomStringConvertible {
    public internal(set) var rawValue: Double
    public internal(set) var width: Int
    var locale: Locale

    public var value: Double {
        (1000.0 * rawValue).rounded() / 10.0
    }

    public var description: String {
        String(format: "%\(width).1f%%", locale: locale, value)
    }

    public init(rawValue: Double, width: Int = 4, locale: Locale = .current) {
        self.rawValue = rawValue
        self.width = width
        self.locale = locale
    }

    public static let zero = Percentage(rawValue: .zero)
}
