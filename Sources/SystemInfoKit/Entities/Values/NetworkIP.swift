enum NetworkIP: Equatable {
    case uninitialized
    case address(String)

    var value: String? {
        switch self {
        case .uninitialized: nil
        case let .address(ip): ip
        }
    }
    
    var displayString: String {
        value ?? "-"
    }
    
    var isInitialized: Bool {
        self != .uninitialized
    }
}
