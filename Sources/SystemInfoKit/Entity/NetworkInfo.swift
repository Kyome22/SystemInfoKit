import Foundation

struct LoadData: Sendable {
    var ip = "-"
    var up = Double.zero
    var down = Double.zero
}

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
    public private(set) var nameValue: String
    public private(set) var ipValue = "-"
    public private(set) var uploadValue = PacketData()
    public private(set) var downloadValue = PacketData()

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

    private func convert(byte: Double) -> PacketData {
        let kb: Double = 1024
        let mb: Double = pow(kb, 2)
        let gb: Double = pow(kb, 3)
        let tb: Double = pow(kb, 4)
        return if tb <= byte {
            PacketData(value: (byte / tb).round2dp, unit: .tb)
        } else if gb <= byte {
            PacketData(value: (byte / gb).round2dp, unit: .gb)
        } else if mb <= byte {
            PacketData(value: (byte / mb).round2dp, unit: .mb)
        } else {
            PacketData(value: (byte / kb).round2dp, unit: .kb)
        }
    }

    mutating func setNameValue(_ value: String) {
        nameValue = value
    }

    mutating func setLoadDataValue(_ value: LoadData) {
        ipValue = value.ip
        uploadValue = convert(byte: value.up)
        downloadValue = convert(byte: value.down)
    }
}
