import Foundation

struct NetworkRepository: SystemRepository {
    typealias TransmissionSpeed = (upload: ByteData, download: ByteData)

    private var nwPathMonitorClient: NWPathMonitorClient
    private var posixClient: POSIXClient
    private var stateClient: StateClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        nwPathMonitorClient = dependencies.nwPathMonitorClient
        posixClient = dependencies.posixClient
        stateClient = dependencies.stateClient
        self.language = language
    }

    private func getPrimaryNetworkInterface() -> NetworkInterface {
        switch nwPathMonitorClient.currentAvailableInterfaceTypes().first {
        case .wifi: .wifi
        case .cellular: .cellular
        case .wiredEthernet: .ethernet
        case .loopback: .loopback
        default: .unknown
        }
    }

    private func getPrimaryIPAddress() -> String? {
        return nwPathMonitorClient.currentGateways().compactMap { endpoint -> String? in
            guard case let .hostPort(host: host, port: _) = endpoint,
                  case let .ipv4(ipv4Address) = host else {
                return nil
            }
            return String(describing: ipv4Address)
        }.first
    }

    private func getDataTraffic(_ pointer: UnsafeMutablePointer<ifaddrs>) -> DataTraffic? {
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        let data = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return DataTraffic(
            upload: Double(data.pointee.ifi_obytes),
            download: Double(data.pointee.ifi_ibytes)
        )
    }

    private func getTransmissionSpeed() -> TransmissionSpeed {
        var result = TransmissionSpeed(
            upload: .init(byteCount: .zero, language: language),
            download: .init(byteCount: .zero, language: language)
        )

        var ifaddrsPointer: UnsafeMutablePointer<ifaddrs>? = nil
        guard posixClient.getIfaddrs(&ifaddrsPointer) == .zero else { return result }

        var pointer = ifaddrsPointer
        var dataTraffics = [DataTraffic]()

        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            if let dataTraffic = getDataTraffic(pointer!) {
                dataTraffics.append(dataTraffic)
            }
        }

        posixClient.freeIfaddrs(ifaddrsPointer)

        let dataTraffic = dataTraffics.reduce(into: DataTraffic.zero) { $0 += $1 }
        let interval = stateClient.withLock(\.interval)
        let previousDataTraffic = stateClient.withLock(\.previousDataTraffic)
        if previousDataTraffic != .zero {
            let dataTrafficDiff = dataTraffic - previousDataTraffic
            result.upload = ByteData(byteCount: dataTrafficDiff.upload / interval, language: language)
            result.download = ByteData(byteCount: dataTrafficDiff.download / interval, language: language)
        }
        stateClient.withLock { [dataTraffic] in $0.previousDataTraffic = dataTraffic }
        return result
    }

    func update() async {
        var result = NetworkInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.networkInfo = result }
        }

        guard nwPathMonitorClient.currentStatus() == .satisfied else {
            return
        }
        result.hasConnection = true
        result.networkInterface = getPrimaryNetworkInterface()
        result.ipAddress = getPrimaryIPAddress()

        let transmissionSpeed = getTransmissionSpeed()
        result.upload = transmissionSpeed.upload
        result.download = transmissionSpeed.download
    }

    func reset() {
        stateClient.withLock {
            $0.bundle.networkInfo = nil
            $0.previousDataTraffic = .zero
        }
    }
}
