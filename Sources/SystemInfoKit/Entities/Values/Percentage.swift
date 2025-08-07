import Foundation

public struct Percentage: Sendable, RawRepresentable, CustomStringConvertible {
    public internal(set) var rawValue: Double
    public internal(set) var width: Int

    public var value: Double {
        (1000.0 * rawValue).rounded() / 10.0
    }

    public var description: String {
        String(format: "%\(width).1f%%", locale: .current, value)
    }

    public init(rawValue: Double, width: Int) {
        self.rawValue = rawValue
        self.width = width
    }

    public init(rawValue: Double) {
        self.init(rawValue: rawValue, width: 4)
    }

    public static let zero = Percentage(rawValue: .zero)
}
