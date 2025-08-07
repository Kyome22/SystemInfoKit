public enum CapacityHealth: Sendable, CustomStringConvertible {
    case maxCapacity(Percentage)
    case condition(Percentage)

    public var description: String {
        switch self {
        case let .maxCapacity(percentage):
            percentage.description
        case let .condition(percentage):
            percentage.description
        }
    }
}
