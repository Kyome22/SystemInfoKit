enum IPAddress: Equatable, CustomStringConvertible {
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

    var description: String {
        value ?? "-"
    }
}
