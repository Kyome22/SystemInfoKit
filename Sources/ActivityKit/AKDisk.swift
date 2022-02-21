//
//  AKDisk.swift
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

public struct ByteData {
    public var value: Double
    public var unit: String
}

public struct AKDiskInfo {

    public var percentage: Double = 0.0
    public var total = ByteData(value: 0.0, unit: "GB")
    public var free = ByteData(value: 0.0, unit: "GB")
    public var used = ByteData(value: 0.0, unit: "GB")
    
    init() {}
    
    init(percentage: Double, total: ByteData, free: ByteData, used: ByteData) {
        self.percentage = percentage
        self.total = total
        self.free = free
        self.used = used
    }

    public var description: String {
        let format = """
        Disk
            Capacity: %.1f%%
            Total: %.1f %@
            Free: %.1f %@
            Used: %.1f %@
        """
        return String(format: format, percentage,
                      total.value, total.unit,
                      free.value, free.unit,
                      used.value, used.unit)
    }
    
}

final public class AKDisk {

    public internal(set) var current = AKDiskInfo()
    
    private func convertByteData(byteCount: Int64) -> ByteData {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .decimal
        let array = fmt.string(fromByteCount: byteCount)
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: .whitespaces)
        return ByteData(value: Double(array[0]) ?? 0.0, unit: array[1])
    }
    
    public func update() {
        var result = AKDiskInfo()
        
        defer {
            current = result
        }
        
        let url = NSURL(fileURLWithPath: "/")
        let keys: [URLResourceKey] = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let dict = try? url.resourceValues(forKeys: keys) else { return }
        let total = (dict[URLResourceKey.volumeTotalCapacityKey] as! NSNumber).int64Value
        let free = (dict[URLResourceKey.volumeAvailableCapacityForImportantUsageKey] as! NSNumber).int64Value
        let used: Int64 = total - free
        
        result.percentage = min(99.9, (100.0 * Double(used) / Double(total)).round2dp)
        
        // support french style 3,14 → 3.14
        result.total = convertByteData(byteCount: total)
        result.free  = convertByteData(byteCount: free)
        result.used  = convertByteData(byteCount: used)
    }
    
}
