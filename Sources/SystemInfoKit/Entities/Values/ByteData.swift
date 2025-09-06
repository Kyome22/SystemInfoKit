import Foundation

public struct ByteData: Sendable, CustomStringConvertible, Localizable {
    public typealias ReadableValue = (value: Double, unit: String)

    public internal(set) var byteCount: Double
    var language: Language

    public var readableValue: ReadableValue {
        let mf = MeasurementFormatter()
        mf.locale = language.locale
        mf.unitStyle = .short
        mf.unitOptions = .naturalScale

        let nf = NumberFormatter()
        nf.locale = language.locale
        nf.numberStyle = .decimal

        let measurment = Measurement<UnitInformationStorage>(value: Double(byteCount), unit: .bytes)

        return if let (count, unit) = mf.string(from: measurment).separete(),
           let value = nf.number(from: count)?.doubleValue {
            (value, unit)
        } else {
            (.zero, "")
        }
    }

    public var description: String {
        let (value, unit) = readableValue
        return string(format: "%4.1f %@", value, unit)
    }

    init(byteCount: Double, language: Language) {
        self.byteCount = byteCount
        self.language = language
    }

    public init(byteCount: Double) {
        self.init(byteCount: byteCount, language: .automatic)
    }

    public static let zero = ByteData(byteCount: .zero)
}

extension ByteData {
    func localized(with language: Language) -> ByteData {
        var copy = self
        copy.language = language
        return copy
    }
}
