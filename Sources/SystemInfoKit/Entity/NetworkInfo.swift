import Foundation

public enum PacketUnit: String, Sendable {
    case kb = "KB/s"
    case mb = "MB/s"
    case gb = "GB/s"
    case tb = "TB/s"
}

public struct PacketData: Sendable, CustomStringConvertible {
    public var value = Double.zero
    public var unit = PacketUnit.kb

    public var description: String {
        String(format: "%5.1f \(unit.rawValue)", value)
    }
}

public struct NetworkInfo: SystemInfo {
    public let type = SystemInfoType.network
    public let value = Double.zero
    public let icon = "network"
    public internal(set) var nameValue: String
    public internal(set) var ipValue = "-"
    public internal(set) var uploadValue = PacketData()
    public internal(set) var downloadValue = PacketData()

    public var summary: String {
        String(localized: "network\(nameValue)", bundle: .module)
    }

    public var details: [String] {
        [
            String(localized: "networkLocalIP\(ipValue)", bundle: .module),
            String(localized: "networkUpload\(uploadValue.description)", bundle: .module),
            String(localized: "networkDownload\(downloadValue.description)", bundle: .module)
        ]
    }

    init() {
        nameValue = String(localized: "networkNoConnection", bundle: .module)
    }
}
