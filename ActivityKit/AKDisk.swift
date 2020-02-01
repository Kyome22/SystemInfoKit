//
//  AKDisk.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

//import Foundation

public struct AKDiskInfo {

    public var percentage: Double = 0.0
    public var total: Double = 0.0
    public var totalUnit: String = "GB"
    public var free: Double = 0.0
    public var freeUnit: String = "GB"
    public var used: Double = 0.0
    public var usedUnit: String = "GB"
    
    public var description: String {
        return String(format: "Disk capacity: %.1f%%, total: %.0f %@, free: %.0f %@, used: %.0f %@",
                      percentage, total, totalUnit, free, freeUnit, used, usedUnit)
    }
    
    init() {}
    
    init(_ percentage: Double,
         _ total: Double, _ totalUnit: String,
         _ free: Double, _ freeUnit: String,
         _ used: Double, _ usedUnit: String) {
        self.percentage = percentage
        self.total = total
        self.totalUnit = totalUnit
        self.free = free
        self.freeUnit = freeUnit
        self.used = used
        self.usedUnit = usedUnit
    }
    
}

final public class AKDisk {
    
    public var info: AKDiskInfo {
        let url = NSURL(fileURLWithPath: "/")
        let keys: [URLResourceKey] = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let dict = try? url.resourceValues(forKeys: keys) else {
            return AKDiskInfo()
        }
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
        
        return AKDiskInfo(percentage,
                          Double(totalArray[0]) ?? 0.0, totalArray[1],
                          Double(freeArray[0]) ?? 0.0, freeArray[1],
                          Double(usedArray[0]) ?? 0.0, usedArray[1])
    }
    
}
