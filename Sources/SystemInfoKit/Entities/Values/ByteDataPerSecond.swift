import Foundation

public struct ByteDataPerSecond: Sendable, CustomStringConvertible {
    public internal(set) var byteData: ByteData

    public var description: String {
        String(format: "%4.1f %@/s", locale: byteData.locale, byteData.value, byteData.unit)
    }

    public init(byteCount: Double, locale: Locale = .current) {
        byteData = .init(byteCount: byteCount, locale: locale)
    }

    public static let zero = ByteDataPerSecond(byteCount: .zero)
}
