import Foundation

struct LoadData {
    var ip: String
    var up: Double
    var down: Double

    init(ip: String = "xxx.xx.x.xxx", up: Double = .zero, down: Double = .zero) {
        self.ip = ip
        self.up = up
        self.down = down
    }
}

struct PacketData: CustomStringConvertible {
    var value: Double
    var unit: String

    var description: String {
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
    private var nameValue: String
    private var loadDataValue = LoadData()
    private var uploadValue = PacketData()
    private var downloadValue = PacketData()

    public var summary: String {
        return String(localized: "network\(nameValue)", bundle: .module)
    }

    public var details: [String] {
        return [
            String(localized: "networkLocalIP\(loadDataValue.ip)", bundle: .module),
            String(localized: "networkUpload\(uploadValue.description)", bundle: .module),
            String(localized: "networkDownload\(downloadValue.description)", bundle: .module)
        ]
    }

    init() {
        self.nameValue = String(localized: "networkNoConnection", bundle: .module)
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
        self.nameValue = value
    }

    mutating func setLoadDataValue(_ value: LoadData) {
        self.loadDataValue = value
        self.uploadValue = convert(byte: value.up)
        self.downloadValue = convert(byte: value.down)
    }
}
