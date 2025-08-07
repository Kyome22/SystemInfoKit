import Foundation

public struct NetworkInfo: SystemInfo {
    public let type = SystemInfoType.network
    public let percentage = Percentage.zero
    public let icon = "network"
    public internal(set) var name: String?
    public internal(set) var ip = "-"
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
            String(localized: "networkLocalIP\(ip)", bundle: .module),
            String(localized: "networkUpload\(upload.description)", bundle: .module),
            String(localized: "networkDownload\(download.description)", bundle: .module)
        ]
    }
}

extension NetworkInfo {
    public static func createMock(
        name: String?,
        ip: String,
        upload: ByteDataPerSecond,
        download: ByteDataPerSecond
    ) -> NetworkInfo {
        NetworkInfo(
            name: name,
            ip: ip,
            upload: upload,
            download: download
        )
    }

    public static let zero = NetworkInfo()
}
