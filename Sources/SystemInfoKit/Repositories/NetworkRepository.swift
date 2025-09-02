import Foundation
import SystemConfiguration

struct NetworkRepository: SystemRepository {
    typealias TransmissionSpeed = (upload: ByteDataPerSecond, download: ByteDataPerSecond)

    private var posixClient: POSIXClient
    private var scDynamicStoreClient: SCDynamicStoreClient
    private var scNetworkInterfaceClient: SCNetworkInterfaceClient
    private var stateClient: StateClient

    init(_ dependencies: Dependencies) {
        posixClient = dependencies.posixClient
        scDynamicStoreClient = dependencies.scDynamicStoreClient
        scNetworkInterfaceClient = dependencies.scNetworkInterfaceClient
        stateClient = dependencies.stateClient
    }

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

    private func getHardwareName(_ id: String) -> String? {
        guard let interfaces = scNetworkInterfaceClient.copyAll() as? [SCNetworkInterface] else {
            return nil
        }
        return interfaces
            .compactMap { interface -> String? in
                guard scNetworkInterfaceClient.getBSDName(interface) as? String == id else { return nil }
                return scNetworkInterfaceClient.getLocalizedDisplayName(interface) as? String
            }
            .first
    }

    private func getDataTraffic(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> DataTraffic? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        var data: UnsafeMutablePointer<if_data>? = nil
        data = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return DataTraffic(
            upload: Double(data?.pointee.ifi_obytes ?? .zero),
            download: Double(data?.pointee.ifi_ibytes ?? .zero)
        )
    }

    private func getIPAddress(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> IPAddress? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        var addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_INET) else { return nil }
        var ip = [CChar](repeating: .zero, count: Int(NI_MAXHOST))
        let result = posixClient.getNameInfo(&addr, socklen_t(addr.sa_len), &ip, socklen_t(ip.count), nil, socklen_t.zero, NI_NUMERICHOST)
        guard result == .zero else { return nil }
        return String(cString: ip, encoding: .utf8).map { IPAddress.v4($0) }
    }

    private func getTransmissionSpeed(_ id: String) -> TransmissionSpeed {
        var result = TransmissionSpeed(.zero, .zero)
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard posixClient.getIfaddrs(&ifaddr) == .zero else { return result }

        var pointer = ifaddr
        var ipAddress = IPAddress.uninitialized
        var dataTraffic = DataTraffic.zero

        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            if !ipAddress.isInitialized, let value = getIPAddress(id, pointer!) {
                ipAddress = value
            }
            if let value = getDataTraffic(id, pointer!) {
                dataTraffic += value
            }
        }
        posixClient.freeIfaddrs(ifaddr)

        if ipAddress.isInitialized {
            stateClient.withLock { [ipAddress] in $0.latestIPAddress = ipAddress }
        }

        let interval = stateClient.withLock(\.interval)
        let previousDataTraffic = stateClient.withLock(\.previousDataTraffic)
        if previousDataTraffic != .zero {
            let dataTrafficDiff = dataTraffic - previousDataTraffic
            result.upload = ByteDataPerSecond(byteCount: dataTrafficDiff.upload / interval)
            result.download = ByteDataPerSecond(byteCount: dataTrafficDiff.download / interval)
        }
        stateClient.withLock { [dataTraffic] in $0.previousDataTraffic = dataTraffic }

        return result
    }

    func update() {
        var result = NetworkInfo()
        defer {
            stateClient.withLock { [result] in $0.bundle.networkInfo = result }
        }

        if let id = getDefaultID() {
            result.name = getHardwareName(id) ?? String(localized: "networkUnknown", bundle: .module)
            let transmissionSpeed = getTransmissionSpeed(id)
            result.ipAddress = stateClient.withLock(\.latestIPAddress)
            result.upload = transmissionSpeed.upload
            result.download = transmissionSpeed.download
        }
    }

    func reset() {
        stateClient.withLock {
            $0.bundle.networkInfo = .init()
            $0.latestIPAddress = .uninitialized
            $0.previousDataTraffic = .zero
        }
    }
}
