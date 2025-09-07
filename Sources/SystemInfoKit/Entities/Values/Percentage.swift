import Foundation

public struct Percentage: Sendable, CustomStringConvertible, Localizable {
    public internal(set) var rawValue: Double
    public internal(set) var width: Int
    var language: Language

    public var value: Double {
        (1000.0 * rawValue).rounded() / 10.0
    }

    public var description: String {
        string(format: "%\(width).1f%%", value)
    }

    init(rawValue: Double, width: Int = 4, language: Language) {
        self.rawValue = rawValue
        self.width = width
        self.language = language
    }

    public init(rawValue: Double, width: Int = 4) {
        self.init(rawValue: rawValue, width: width, language: .automatic)
    }

    public static let zero = Percentage(rawValue: .zero)
}

extension Percentage {
    func localized(with language: Language) -> Percentage {
        var copy = self
        copy.language = language
        return copy
    }
}
