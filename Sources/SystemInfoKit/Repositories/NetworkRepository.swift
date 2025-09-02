import Foundation
import SystemConfiguration

struct NetworkRepository: SystemRepository {
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

    private func getNetworkLoad(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> NetworkLoad? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        var data: UnsafeMutablePointer<if_data>? = nil
        data = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return NetworkLoad(
            upload: Int64(data?.pointee.ifi_obytes ?? 0),
            download: Int64(data?.pointee.ifi_ibytes ?? 0)
        )
    }

    private func getIPAddress(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> String? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        var addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_INET) else { return nil }
        var ip = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(&addr, socklen_t(addr.sa_len), &ip, socklen_t(ip.count), nil, socklen_t(0), NI_NUMERICHOST)
        return String(cString: ip, encoding: .utf8)
    }

    private func getNetworkByteData(_ id: String) -> NetworkByteData {
        var result = NetworkByteData()
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == .zero else { return result }

        var pointer = ifaddr
        var detectedIP = NetworkIP.uninitialized
        var networkLoad = NetworkLoad.zero

        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            if !detectedIP.isInitialized, let value = getIPAddress(id, pointer!) {
                detectedIP = .address(value)
            }
            if let value = getNetworkLoad(id, pointer!) {
                networkLoad += value
            }
        }
        freeifaddrs(ifaddr)

        if detectedIP.isInitialized {
            systemInfoStateClient.withLock { [detectedIP] in $0.latestIP = detectedIP }
        }

        let interval = systemInfoStateClient.withLock(\.interval)
        let previousNetworkLoad = systemInfoStateClient.withLock(\.previousNetworkLoad)
        if previousNetworkLoad != .zero {
            let networkLoadDiff = networkLoad - previousNetworkLoad
            result.upload = ByteDataPerSecond(byteCount: Int64(Double(networkLoadDiff.upload) / interval))
            result.download = ByteDataPerSecond(byteCount: Int64(Double(networkLoadDiff.download) / interval))
        }
        systemInfoStateClient.withLock { [networkLoad] in $0.previousNetworkLoad = networkLoad }

        return result
    }

    func update() {
        var result = NetworkInfo()
        defer {
            systemInfoStateClient.withLock { [result] in $0.bundle.networkInfo = result }
        }

        if let id = getDefaultID() {
            result.name = getHardwareName(id)
            let networkByteData = getNetworkByteData(id)
            result.ip = systemInfoStateClient.withLock(\.latestIP.displayString)
            result.upload = networkByteData.upload
            result.download = networkByteData.download
        }
    }

    func reset() {
        systemInfoStateClient.withLock {
            $0.bundle.networkInfo = .init()
            $0.latestIP = .uninitialized
            $0.previousNetworkLoad = .zero
        }
    }
}
