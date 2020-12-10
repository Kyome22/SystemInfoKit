//
//  AKNetwork.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright 2020 Takuto Nakamura
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SystemConfiguration

public struct LoadData {
    public var ip: String
    public var up: Double
    public var down: Double
}

public struct PacketData {
    public var value: Double
    public var unit: String
}

public struct AKNetworkInfo {
    
    public var name: String = "no connection"
    public var localIP: String = "xx.x.x.xx"
    public var upload = PacketData(value: 0.0, unit: "KB/s")
    public var download = PacketData(value: 0.0, unit: "KB/s")
    
    public var description: String {
        let format = """
        Network
            Name %@
            Local IP: %@
            Upload: %.1f %@
            Download: %.1f %@
        """
        return String(format: format, name, localIP,
                      upload.value, upload.unit,
                      download.value, download.unit)
    }
    
    init() {}
    
    init(name: String, load: LoadData) {
        self.name = name
        self.localIP = load.ip
        self.upload = convert(byte: load.up)
        self.download = convert(byte: load.down)
    }

    private func convert(byte: Double) -> PacketData {
        let KB: Double = 1024
        let MB: Double = pow(KB, 2)
        let GB: Double = pow(KB, 3)
        let TB: Double = pow(KB, 4)
        if TB <= byte {
            return PacketData(value: (10 * byte / TB).rounded() / 10, unit: "TB/s")
        } else if GB <= byte {
            return PacketData(value: (10 * byte / GB).rounded() / 10, unit: "GB/s")
        } else if MB <= byte {
            return PacketData(value: (10 * byte / MB).rounded() / 10, unit: "MB/s")
        } else {
            return PacketData(value: (10 * byte / KB).rounded() / 10, unit: "KB/s")
        }
    }
    
}

final public class AKNetwork {

    public internal(set) var current = AKNetworkInfo()
    
    private var interval: Double = 1.0
    private var previousIP: String = "xx.x.x.xx"
    private var previousUpload: Int64 = 0
    private var previousDownload: Int64 = 0

    public func update(interval: Double) {
        self.interval = max(interval, 1.0)
        guard let id = getDefaultID else { return }
        let name = getHardwareName(id)
        let load = getUpDown(id)
        current = AKNetworkInfo(name: name, load: load)
    }
    
    private var getDefaultID: String? {
//        let key = "State:/Network/Global/IPv4" as CFString
//        guard let plist = SCDynamicStoreCopyValue(nil, key) as? [String: AnyObject] else {
//            return nil
//        }
//        return plist[kSCDynamicStorePropNetPrimaryInterface as String] as? String

        let processName = ProcessInfo.processInfo.processName as CFString
        let dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, processName, nil, nil)
        let ipv4Key = SCDynamicStoreKeyCreateNetworkGlobalEntity(kCFAllocatorDefault,
                                                                 kSCDynamicStoreDomainState,
                                                                 kSCEntNetIPv4)
        guard let list = SCDynamicStoreCopyValue(dynamicStore, ipv4Key) as? [CFString: Any],
              let interface = list[kSCDynamicStorePropNetPrimaryInterface] as? String
        else { return nil }
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
        return "Unknown"
    }
    
    private func getUpDown(_ id: String) -> LoadData {
        var result = LoadData(ip: "xx.x.x.xx", up: 0.0, down: 0.0)
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
            result.up = Double(upload - previousUpload) / interval
            result.down = Double(download - previousDownload) / interval
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
    
}
