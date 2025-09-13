import Foundation

public struct NetworkInfo: LocalizableSystemInfo {
    public let type = SystemInfoType.network
    public let percentage = Percentage.zero
    public internal(set) var hasConnection: Bool
    public internal(set) var networkInterface: NetworkInterface
    public internal(set) var ipAddress: String?
    public internal(set) var upload: ByteData
    public internal(set) var download: ByteData
    var language: Language

    public var icon: String { type.icon }

    private var network: String {
        if hasConnection {
            switch networkInterface {
            case .wifi:
                "Wi-Fi"
            case .cellular:
                string(localized: "networkCellular")
            case .ethernet:
                "Ethernet"
            case .loopback:
                "Loopback"
            case .unknown:
                string(localized: "networkUnknown")
            }
        } else {
            string(localized: "networkNoConnection")
        }
    }

    public var summary: String {
        string(localized: "network\(network)")
    }

    public var details: [String] {
        [
            string(localized: "networkLocalIP\(ipAddress ?? "-")"),
            string(localized: "networkUpload\(String(describing: upload))"),
            string(localized: "networkDownload\(String(describing: download))"),
        ]
    }

    init(
        hasConnection: Bool = false,
        networkInterface: NetworkInterface = .unknown,
        ipAddress: String? = nil,
        upload: ByteData = .zero,
        download: ByteData = .zero,
        language: Language
    ) {
        self.hasConnection = hasConnection
        self.networkInterface = networkInterface
        self.ipAddress = ipAddress
        self.upload = upload.localized(with: language)
        self.download = download.localized(with: language)
        self.language = language
    }

    public init(
        hasConnection: Bool,
        networkInterface: NetworkInterface,
        ipAddress: String?,
        upload: ByteData,
        download: ByteData
    ) {
        self.init(
            hasConnection: hasConnection,
            networkInterface: networkInterface,
            ipAddress: ipAddress,
            upload: upload,
            download: download,
            language: .automatic
        )
    }

    public static let zero = NetworkInfo(language: .automatic)
}
