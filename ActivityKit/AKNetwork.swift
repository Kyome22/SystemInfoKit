//
//  AKNetwork.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

import SystemConfiguration

typealias LoadData = (ip: String, up: Double, upUnit: String, down: Double, downUnit: String)

public struct AKNetworkInfo {
    
    public var name: String = "no connection"
    public var localIP: String = "xx.x.x.xx"
    public var upload: Double = 0.0
    public var uploadUnit: String = "KB/s"
    public var download: Double = 0.0
    public var downloadUnit: String = "KB/s"
    
    public var description: String {
        return String(format: "Network: %@, Local IP: %@, upload: %.1f %@, download: %.1f %@",
                      name, localIP, upload, uploadUnit, download, downloadUnit)
    }
    
    init() {}
    
    init(_ name: String, _ load: LoadData) {
        self.name = name
        self.localIP = load.ip
        self.upload = load.up
        self.uploadUnit = load.upUnit
        self.download = load.down
        self.downloadUnit = load.downUnit
    }
    
}

final public class AKNetwork {
    
    private var interval: Double = 1.0
    private var previousIP: String = "xx.x.x.xx"
    private var previousUpload: Int64 = 0
    private var previousDownload: Int64 = 0
    
    init(interval: Double) {
        self.interval = max(interval, 1.0)
    }
    
    private var getDefaultID: String? {
        guard let global = SCDynamicStoreCopyValue(nil, "State:/Network/Global/IPv4" as CFString) else {
            return nil
        }
        return global["PrimaryInterface"] as? String
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
        return "Unknown"
    }
    
    private func getUpDown(_ id: String) -> LoadData {
        var result: LoadData = ("xx.x.x.xx", 0.0, "KB/s", 0.0, "KB/s")
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return result }

        var pointer = ifaddr
        var upload: Int64 = 0
        var download: Int64 = 0
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            if let info = getBytesInfo(id, pointer!) {
                upload += info.up
                download += info.down
            }
            if let ip = getIPAddress(id, pointer!) {
                if previousIP != ip {
                    previousUpload = 0
                    previousDownload = 0
                }
                previousIP = ip
            }
        }
        result.ip = previousIP
        freeifaddrs(ifaddr)
        if previousUpload != 0 && previousDownload != 0 {
            let up = convert(byte: Double(upload - previousUpload) / interval)
            let down = convert(byte: Double(download - previousDownload) / interval)
            result.up = up.value
            result.upUnit = up.unit
            result.down = down.value
            result.downUnit = down.unit
        }
        previousUpload = upload
        previousDownload = download
        return result
    }
    
    private func getBytesInfo(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> (up: Int64, down: Int64)? {
        let name = String(cString: pointer.pointee.ifa_name)
        if name == id {
            let addr = pointer.pointee.ifa_addr.pointee
            guard addr.sa_family == UInt8(AF_LINK) else { return nil }
            var data: UnsafeMutablePointer<if_data>? = nil
            data = unsafeBitCast(pointer.pointee.ifa_data,
                                 to: UnsafeMutablePointer<if_data>.self)
            return (up: Int64(data?.pointee.ifi_obytes ?? 0),
                    down: Int64(data?.pointee.ifi_ibytes ?? 0))
        }
        return nil
    }
    
    private func getIPAddress(_ id: String, _ pointer: UnsafeMutablePointer<ifaddrs>) -> String? {
        let name = String(cString: pointer.pointee.ifa_name)
        if name == id {
            var addr = pointer.pointee.ifa_addr.pointee
            guard addr.sa_family == UInt8(AF_INET) else { return nil }
            var ip = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(&addr, socklen_t(addr.sa_len), &ip,
                        socklen_t(ip.count), nil, socklen_t(0), NI_NUMERICHOST)
            return String(cString: ip)
        }
        return nil
    }
    
    private func convert(byte: Double) -> (value: Double, unit: String) {
        let KB: Double = 1024
        let MB: Double = pow(KB, 2)
        let GB: Double = pow(KB, 3)
        let TB: Double = pow(KB, 4)
        if TB <= byte {
            return ((10 * byte / TB).rounded() / 10, "TB/s")
        } else if GB <= byte {
            return ((10 * byte / GB).rounded() / 10, "GB/s")
        } else if MB <= byte {
            return ((10 * byte / MB).rounded() / 10, "MB/s")
        }
        return ((10 * byte / KB).rounded() / 10, "KB/s")
    }
    
    public var info: AKNetworkInfo {
        guard let id = getDefaultID else { return AKNetworkInfo() }
        return AKNetworkInfo(getHardwareName(id), getUpDown(id))
    }
    
}
