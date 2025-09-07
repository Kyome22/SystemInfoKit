protocol SystemInfo: Sendable, CustomStringConvertible, Localizable {
    var type: SystemInfoType { get }
    var icon: String { get }
    var percentage: Percentage { get }
    var summary: String { get }
    var details: [String] { get }
}

extension SystemInfo {
    var _description: String {
        var text = "\(summary)\n"
        text += details.map { "\t\($0)" }.joined(separator: "\n")
        return text
    }

    public var description: String {
        _description
    }
}
