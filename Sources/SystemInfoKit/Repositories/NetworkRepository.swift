import Foundation
import SystemConfiguration

struct NetworkRepository: SystemRepository {
    typealias TransmissionSpeed = (upload: ByteDataPerSecond, download: ByteDataPerSecond)

    private var systemInfoStateClient: SystemInfoStateClient

    init(_ systemInfoStateClient: SystemInfoStateClient) {
        self.systemInfoStateClient = systemInfoStateClient
    }

    private func getDefaultID() -> String? {
        let processName = ProcessInfo.processInfo.processName as CFString
        let dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, processName, nil, nil)
        let ipv4Key = SCDynamicStoreKeyCreateNetworkGlobalEntity(kCFAllocatorDefault,
                                                                 kSCDynamicStoreDomainState,
                                                                 kSCEntNetIPv4)
        guard let list = SCDynamicStoreCopyValue(dynamicStore, ipv4Key) as? [CFString: Any],
              let interface = list[kSCDynamicStorePropNetPrimaryInterface] as? String else {
            return nil
        }
        return interface
    }

    private func getHardwareName(_ id: String) -> String {
        for interface in SCNetworkInterfaceCopyAll() as! [SCNetworkInterface] {
            if let bsd = SCNetworkInterfaceGetBSDName(interface) {
                if bsd as String != id { continue }
                if let name = SCNetworkInterfaceGetLocalizedDisplayName(interface) {
                    return name as String
                }
            }
        }
        return String(localized: "networkUnknown", bundle: .module)
    }

    private func getDataTraffic(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> DataTraffic? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        var data: UnsafeMutablePointer<if_data>? = nil
        data = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return DataTraffic(
            upload: Int64(data?.pointee.ifi_obytes ?? .zero),
            download: Int64(data?.pointee.ifi_ibytes ?? .zero)
        )
    }

    private func getIPAddress(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> IPAddress? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        var addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_INET) else { return nil }
        var ip = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(&addr, socklen_t(addr.sa_len), &ip, socklen_t(ip.count), nil, socklen_t(0), NI_NUMERICHOST)
        return String(cString: ip, encoding: .utf8).map { IPAddress.v4($0) }
    }

    private func getTransmissionSpeed(_ id: String) -> TransmissionSpeed {
        var result = TransmissionSpeed(.zero, .zero)
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == .zero else { return result }

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
        freeifaddrs(ifaddr)

        if ipAddress.isInitialized {
            systemInfoStateClient.withLock { [ipAddress] in $0.latestIPAddress = ipAddress }
        }

        let interval = systemInfoStateClient.withLock(\.interval)
        let previousDataTraffic = systemInfoStateClient.withLock(\.previousDataTraffic)
        if previousDataTraffic != .zero {
            let dataTrafficDiff = dataTraffic - previousDataTraffic
            result.upload = ByteDataPerSecond(byteCount: Int64(Double(dataTrafficDiff.upload) / interval))
            result.download = ByteDataPerSecond(byteCount: Int64(Double(dataTrafficDiff.download) / interval))
        }
        systemInfoStateClient.withLock { [dataTraffic] in $0.previousDataTraffic = dataTraffic }

        return result
    }

    func update() {
        var result = NetworkInfo()
        defer {
            systemInfoStateClient.withLock { [result] in $0.bundle.networkInfo = result }
        }

        if let id = getDefaultID() {
            result.name = getHardwareName(id)
            let transmissionSpeed = getTransmissionSpeed(id)
            result.ipAddress = systemInfoStateClient.withLock(\.latestIPAddress)
            result.upload = transmissionSpeed.upload
            result.download = transmissionSpeed.download
        }
    }

    func reset() {
        systemInfoStateClient.withLock {
            $0.bundle.networkInfo = .init()
            $0.latestIPAddress = .uninitialized
            $0.previousDataTraffic = .zero
        }
    }
}
