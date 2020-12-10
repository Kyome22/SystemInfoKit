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
    
    public func update() {
        let url = NSURL(fileURLWithPath: "/")
        let keys: [URLResourceKey] = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let dict = try? url.resourceValues(forKeys: keys) else { return }
        let total = (dict[URLResourceKey.volumeTotalCapacityKey] as! NSNumber).int64Value
        let free = (dict[URLResourceKey.volumeAvailableCapacityForImportantUsageKey] as! NSNumber).int64Value
        let used: Int64 = total - free
        let percentage: Double = min(99.9, round(1000.0 * Double(used) / Double(total)) / 10.0)
        
        let fmt = ByteCountFormatter()
        fmt.countStyle = .decimal
        // support french style 3,14 → 3.14
        let totalArray = fmt.string(fromByteCount: total)
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: .whitespaces)
        let freeArray = fmt.string(fromByteCount: free)
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: .whitespaces)
        let usedArray = fmt.string(fromByteCount: used)
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: .whitespaces)
        
        current = AKDiskInfo(percentage: percentage,
                             total: ByteData(value: Double(totalArray[0]) ?? 0.0, unit: totalArray[1]),
                             free: ByteData(value: Double(freeArray[0]) ?? 0.0, unit: freeArray[1]),
                             used: ByteData(value: Double(usedArray[0]) ?? 0.0, unit: usedArray[1]))
    }
    
}
