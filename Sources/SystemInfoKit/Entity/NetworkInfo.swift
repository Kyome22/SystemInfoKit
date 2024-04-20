import Foundation

struct LoadData {
    var ip: String
    var up: Double
    var down: Double

    init(ip: String = "-", up: Double = .zero, down: Double = .zero) {
        self.ip = ip
        self.up = up
        self.down = down
    }
}

public struct PacketData: CustomStringConvertible {
    public var value: Double
    public var unit: String

    public var description: String {
        return String(format: "%5.1f \(unit)", value)
    }

    init(value: Double = .zero, unit: String = "KB/s") {
        self.value = value
        self.unit = unit
    }
}

public struct NetworkInfo: SystemInfo {
    public let type: SystemInfoType = .network
    public let value: Double = .zero
    public let icon: String = "network"
    public private(set) var nameValue: String
    public private(set) var ipValue: String = "-"
    public private(set) var uploadValue = PacketData()
    public private(set) var downloadValue = PacketData()

    public var summary: String {
        return String(localized: "network\(nameValue)", bundle: .module)
    }

    public var details: [String] {
        return [
            String(localized: "networkLocalIP\(ipValue)", bundle: .module),
            String(localized: "networkUpload\(uploadValue.description)", bundle: .module),
            String(localized: "networkDownload\(downloadValue.description)", bundle: .module)
        ]
    }

    init() {
        nameValue = String(localized: "networkNoConnection", bundle: .module)
    }

    private func convert(byte: Double) -> PacketData {
        let KB: Double = 1024
        let MB: Double = pow(KB, 2)
        let GB: Double = pow(KB, 3)
        let TB: Double = pow(KB, 4)
        if TB <= byte {
            return PacketData(value: (byte / TB).round2dp, unit: "TB/s")
        } else if GB <= byte {
            return PacketData(value: (byte / GB).round2dp, unit: "GB/s")
        } else if MB <= byte {
            return PacketData(value: (byte / MB).round2dp, unit: "MB/s")
        } else {
            return PacketData(value: (byte / KB).round2dp, unit: "KB/s")
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
