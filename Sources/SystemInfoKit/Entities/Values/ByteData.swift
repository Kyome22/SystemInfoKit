import Foundation

public struct ByteData: Sendable, CustomStringConvertible {
    public internal(set) var value: Double
    public internal(set) var unit: String
    var locale: Locale

    public var description: String {
        String(format: "%4.1f %@", locale: locale, value, unit)
    }

    public init(byteCount: Double, locale: Locale = .current) {
        self.locale = locale

        let mf = MeasurementFormatter()
        mf.locale = locale
        mf.unitStyle = .short
        mf.unitOptions = .naturalScale

        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal

        let measurment = Measurement<UnitInformationStorage>(value: Double(byteCount), unit: .bytes)

        (value, unit) = if let (count, unit) = mf.string(from: measurment).separete(),
                           let value = nf.number(from: count)?.doubleValue {
            (value, unit)
        } else {
            (.zero, "")
        }
    }

    public static let zero = ByteData(byteCount: .zero)
}
