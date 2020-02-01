//
//  AKCPU.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

import Darwin

public struct AKCPUInfo {
    
    public var percentage: Double = 0.0
    public var system: Double = 0.0
    public var user: Double = 0.0
    public var idle: Double = 0.0
    
    public var description: String {
        return String(format: "CPU usage: %.1f%%, system: %.1f%%, user: %.1f%%, idle: %.1f%%",
                      percentage, system, user, idle)
    }
        
    init() {}
    
    init(_ percentage: Double, _ system: Double, _ user: Double, _ idle: Double) {
        self.percentage = percentage
        self.system = system
        self.user = user
        self.idle = idle
    }
    
}

final public class AKCPU {
    
    private let loadInfoCount: mach_msg_type_number_t!
    private var loadPrevious = host_cpu_load_info()
    
    init() {
        loadInfoCount = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
    }
    
    private func hostCPULoadInfo() -> host_cpu_load_info {
        var size: mach_msg_type_number_t = loadInfoCount
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { (pointer) -> kern_return_t in
            return host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    
    public var info: AKCPUInfo {
        let load = hostCPULoadInfo()
        
        let userDiff    = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
        let systemDiff  = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
        let idleDiff    = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
        let niceDiff    = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)
        loadPrevious    = load
        
        let totalTicks = systemDiff + userDiff + idleDiff + niceDiff
        let system     = 100.0 * systemDiff / totalTicks
        let user       = 100.0 * userDiff / totalTicks
        let idle       = 100.0 * idleDiff / totalTicks
        let percentage = min(99.9, round((system + user) * 10.0) / 10.0)
        return AKCPUInfo(percentage, system, user, idle)
    }
    
}
