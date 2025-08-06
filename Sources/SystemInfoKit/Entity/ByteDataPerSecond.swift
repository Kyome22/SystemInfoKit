import Foundation

public struct ByteDataPerSecond: Sendable, CustomStringConvertible {
    public internal(set) var byteData: ByteData

    public var description: String {
        String(format: "%4.1f %@/s", locale: Locale.current, byteData.value, byteData.unit)
    }

    public init(byteCount: Int64) {
        byteData = .init(byteCount: byteCount)
    }

    public static let zero = ByteDataPerSecond(byteCount: .zero)
}
