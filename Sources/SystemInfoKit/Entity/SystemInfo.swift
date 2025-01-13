public protocol SystemInfo: Sendable, CustomStringConvertible {
    var type: SystemInfoType { get }
    var value: Double { get }
    var icon: String { get }
    var summary: String { get }
    var details: [String] { get }
}

extension SystemInfo {
    public var description: String {
        var text = "\(summary)\n"
        text += details.map { "\t\($0)" }.joined(separator: "\n")
        return text
    }
}
