import Foundation
import SystemConfiguration

struct NetworkRepository: Sendable {
    var current = NetworkInfo()
    private var interval: Double = 1.0
    private var previousIP = "-"
    private var previousUpload = Int64.zero
    private var previousDownload = Int64.zero

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

    private func getBytesInfo(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> (up: Int64, down: Int64)? {
        let name = String(cString: pointer.pointee.ifa_name)
        guard name == id else { return nil }
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        var data: UnsafeMutablePointer<if_data>? = nil
        data = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return (up: Int64(data?.pointee.ifi_obytes ?? 0),
                down: Int64(data?.pointee.ifi_ibytes ?? 0))
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

    private func convert(byte: Double) -> PacketData {
        let kb: Double = 1024
        let mb: Double = pow(kb, 2)
        let gb: Double = pow(kb, 3)
        let tb: Double = pow(kb, 4)
        return if tb <= byte {
            PacketData(value: (byte / tb).round2dp, unit: .tb)
        } else if gb <= byte {
            PacketData(value: (byte / gb).round2dp, unit: .gb)
        } else if mb <= byte {
            PacketData(value: (byte / mb).round2dp, unit: .mb)
        } else {
            PacketData(value: (byte / kb).round2dp, unit: .kb)
        }
    }

    private mutating func getUpDown(_ id: String) -> UpDownPacketData {
        var result = UpDownPacketData()
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == .zero else { return result }

        var pointer = ifaddr
        var upload: Int64 = .zero
        var download: Int64 = .zero
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            if let info = getBytesInfo(id, pointer!) {
                upload += info.up
                download += info.down
            }
            if let ip = getIPAddress(id, pointer!) {
                if previousIP != ip {
                    previousUpload = .zero
                    previousDownload = .zero
                }
                previousIP = ip
            }
        }
        freeifaddrs(ifaddr)
        if previousUpload != .zero && previousDownload != .zero {
            result.upload = convert(byte: Double(upload - previousUpload) / interval)
            result.download = convert(byte: Double(download - previousDownload) / interval)
        }
        previousUpload = upload
        previousDownload = download
        return result
    }

    mutating func update(interval: Double) {
        var result = NetworkInfo()

        defer {
            current = result
        }

        self.interval = max(interval, 1.0)
        if let id = getDefaultID() {
            result.nameValue = getHardwareName(id)
            let upDown = getUpDown(id)
            result.ipValue = previousIP
            result.uploadValue = upDown.upload
            result.downloadValue = upDown.download
        }
    }

    mutating func reset() {
        current = NetworkInfo()
    }

    private struct UpDownPacketData {
        var upload = PacketData()
        var download = PacketData()
    }
}
