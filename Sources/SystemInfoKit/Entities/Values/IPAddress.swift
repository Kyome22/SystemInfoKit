public enum IPAddress: Sendable, Equatable, CustomStringConvertible {
    case uninitialized
    case v4(String)

    var value: String? {
        switch self {
        case .uninitialized: nil
        case let .v4(value): value
        }
    }
    
    var isInitialized: Bool {
        self != .uninitialized
    }

    public var description: String {
        value ?? "-"
    }
}
