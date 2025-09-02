import Foundation

public struct NetworkInfo: SystemInfo {
    public let type = SystemInfoType.network
    public let percentage = Percentage.zero
    public let icon = "network"
    public internal(set) var name: String?
    public internal(set) var ipAddress = IPAddress.uninitialized
    public internal(set) var upload = ByteDataPerSecond.zero
    public internal(set) var download = ByteDataPerSecond.zero

    public var summary: String {
        if let name {
            String(localized: "network\(name)", bundle: .module)
        } else {
            String(localized: "networkNoConnection", bundle: .module)
        }
    }

    public var details: [String] {
        [
            String(localized: "networkLocalIP\(String(describing: ipAddress))", bundle: .module),
            String(localized: "networkUpload\(String(describing: upload))", bundle: .module),
            String(localized: "networkDownload\(String(describing: download))", bundle: .module)
        ]
    }
}

extension NetworkInfo {
    public static func createMock(
        name: String?,
        ipAddress: IPAddress,
        upload: ByteDataPerSecond,
        download: ByteDataPerSecond
    ) -> NetworkInfo {
        NetworkInfo(
            name: name,
            ipAddress: ipAddress,
            upload: upload,
            download: download
        )
    }

    public static let zero = NetworkInfo()
}
