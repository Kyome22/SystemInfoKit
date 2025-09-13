public protocol SystemInfo: Sendable, CustomStringConvertible {
    var type: SystemInfoType { get }
    var icon: String { get }
    var percentage: Percentage { get }
    var summary: String { get }
    var details: [String] { get }
}

extension SystemInfo {
    var _description: String {
        ([summary] + details).joined(separator: "\n\t")
    }

    public var description: String {
        _description
    }
}

protocol LocalizableSystemInfo: SystemInfo, Localizable {}
