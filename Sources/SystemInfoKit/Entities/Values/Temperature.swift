import Foundation

public struct Temperature: Sendable, CustomStringConvertible, Localizable {
    public internal(set) var value: Double
    var language: Language

    public var description: String {
        string(format: "%4.1f°C", value)
    }

    init(value: Double, language: Language) {
        self.value = value
        self.language = language
    }

    public init(value: Double) {
        self.init(value: value, language: .automatic)
    }

    public static let zero = Temperature(value: .zero)
}

extension Temperature {
    func localized(with language: Language) -> Temperature {
        var copy = self
        copy.language = language
        return copy
    }
}
