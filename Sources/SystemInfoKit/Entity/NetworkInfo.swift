import Foundation

public struct NetworkInfo: SystemInfo {
    public let type = SystemInfoType.network
    public let value = Double.zero
    public let icon = "network"
    public internal(set) var nameValue: String?
    public internal(set) var ipValue = "-"
    public internal(set) var uploadValue = ByteDataPerSecond.zero
    public internal(set) var downloadValue = ByteDataPerSecond.zero

    public var summary: String {
        if let nameValue {
            String(localized: "network\(nameValue)", bundle: .module)
        } else {
            String(localized: "networkNoConnection", bundle: .module)
        }
    }

    public var details: [String] {
        [
            String(localized: "networkLocalIP\(ipValue)", bundle: .module),
            String(localized: "networkUpload\(uploadValue.description)", bundle: .module),
            String(localized: "networkDownload\(downloadValue.description)", bundle: .module)
        ]
    }
}

extension NetworkInfo {
    public static func createMock(
        nameValue: String?,
        ipValue: String,
        uploadValue: ByteDataPerSecond,
        downloadValue: ByteDataPerSecond
    ) -> NetworkInfo {
        NetworkInfo(
            nameValue: nameValue,
            ipValue: ipValue,
            uploadValue: uploadValue,
            downloadValue: downloadValue
        )
    }

    public static let zero = NetworkInfo()
}
