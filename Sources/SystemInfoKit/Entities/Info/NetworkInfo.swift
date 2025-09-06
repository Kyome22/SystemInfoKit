import Foundation

public struct NetworkInfo: SystemInfo {
    public let type = SystemInfoType.network
    public let percentage = Percentage.zero
    public internal(set) var name: String?
    public internal(set) var ipAddress: IPAddress
    public internal(set) var upload: ByteData
    public internal(set) var download: ByteData
    var language: Language

    public var icon: String { type.icon }

    public var summary: String {
        if let name {
            string(localized: "network\(name)")
        } else {
            string(localized: "networkNoConnection")
        }
    }

    public var details: [String] {
        [
            string(localized: "networkLocalIP\(String(describing: ipAddress))"),
            string(localized: "networkUpload\(String(describing: upload))"),
            string(localized: "networkDownload\(String(describing: download))"),
        ]
    }

    init(
        name: String? = nil,
        ipAddress: IPAddress = .uninitialized,
        upload: ByteData = .zero,
        download: ByteData = .zero,
        language: Language
    ) {
        self.name = name
        self.ipAddress = ipAddress
        self.upload = upload.localized(with: language)
        self.download = download.localized(with: language)
        self.language = language
    }

    public init(
        name: String?,
        ipAddress: IPAddress,
        upload: ByteData,
        download: ByteData
    ) {
        self.init(
            name: name,
            ipAddress: ipAddress,
            upload: upload,
            download: download,
            language: .automatic
        )
    }

    public static let zero = NetworkInfo(language: .automatic)
}
