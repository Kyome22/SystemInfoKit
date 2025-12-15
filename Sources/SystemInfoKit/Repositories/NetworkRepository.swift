import Foundation
import SystemConfiguration

struct NetworkRepository: SystemRepository {
    typealias TransmissionSpeed = (upload: ByteData, download: ByteData)

    private var nwPathMonitorClient: NWPathMonitorClient
    private var posixClient: POSIXClient
    private var scDynamicStoreClient: SCDynamicStoreClient
    private var scNetworkInterfaceClient: SCNetworkInterfaceClient
    private var stateClient: StateClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        nwPathMonitorClient = dependencies.nwPathMonitorClient
        posixClient = dependencies.posixClient
        scDynamicStoreClient = dependencies.scDynamicStoreClient
        scNetworkInterfaceClient = dependencies.scNetworkInterfaceClient
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

    private func getValueFromIfaddrs<Value>(
        into initialValue: Value,
        updateValue: (inout Value, UnsafeMutablePointer<ifaddrs>) -> Void
    ) -> Value {
        var value = initialValue
        var ifaddrsPointer: UnsafeMutablePointer<ifaddrs>? = nil
        guard posixClient.getIfaddrs(&ifaddrsPointer) == .zero else {
            return value
        }
        var pointer = ifaddrsPointer
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            updateValue(&value, pointer!)
        }
        posixClient.freeIfaddrs(ifaddrsPointer)
        return value
    }

    private func getIPAddress(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> String? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        var addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_INET) else { return nil }
        var ip = [CChar](repeating: .zero, count: Int(NI_MAXHOST))
        let result = posixClient.getNameInfo(&addr, socklen_t(addr.sa_len), &ip, socklen_t(ip.count), nil, socklen_t.zero, NI_NUMERICHOST)
        guard result == .zero else { return nil }
        return String(cString: ip, encoding: .utf8)
    }

    private func getPrimaryIPAddress() -> String? {
        guard let id = getDefaultID() else { return nil }
        return getValueFromIfaddrs(into: String?.none) { value, pointer in
            guard let ipAddress = getIPAddress(id, pointer) else { return }
            value = ipAddress
        }
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
        let dataTraffic = getValueFromIfaddrs(into: DataTraffic.zero) { value, pointer in
            guard let dataTraffic = getDataTraffic(pointer) else { return }
            value += dataTraffic
        }
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

#if os(macOS)
extension NetworkRepository {
    private func getDefaultID() -> String? {
        let processName = ProcessInfo.processInfo.processName as CFString
        let dynamicStore = scDynamicStoreClient.create(kCFAllocatorDefault, processName, nil, nil)
        let ipv4Key = scDynamicStoreClient.keyCreateNetworkGlobalEntity(
            kCFAllocatorDefault,
            kSCDynamicStoreDomainState,
            kSCEntNetIPv4
        )
        guard let list = scDynamicStoreClient.copyValue(dynamicStore, ipv4Key) as? [CFString: Any],
              let interface = list[kSCDynamicStorePropNetPrimaryInterface] as? String else {
            return nil
        }
        return interface
    }
}
#elseif os(iOS)
extension NetworkRepository {
    private func getDefaultID() -> String? {
        nwPathMonitorClient.currentAvailableInterfaceNames().first
    }
}
#endif
