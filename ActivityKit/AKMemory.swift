//
//  AKMemory.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

import Darwin

public struct AKMemoryInfo {
    
    public var percentage: Double = 0.0
    public var pressure: Double = 0.0
    public var app: Double = 0.0
    public var wired: Double = 0.0
    public var compressed: Double = 0.0
    
    public var description: String {
        return String(format: "Memory performance: %.1f%%, pressure: %.1f%%, app: %.1f GB, wired: %.1f GB, compressed: %.1f GB",
                      percentage, pressure, app, wired, compressed)
    }
    
    init() {}
    
    init(_ percentage: Double, _ pressure: Double, _ app: Double, _ wired: Double, _ compressed: Double) {
        self.percentage = percentage
        self.pressure = pressure
        self.app = app
        self.wired = wired
        self.compressed = compressed
    }
    
}

final public class AKMemory {
    
    private let gigaByte: Double = 1073741824
    private let hostVmInfo64Count: mach_msg_type_number_t!
    private let hostBasicInfoCount: mach_msg_type_number_t!
    
    init() {
        hostVmInfo64Count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        hostBasicInfoCount = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
    }
    
    private var maxMemory: Double {
        var size: mach_msg_type_number_t = hostBasicInfoCount
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int()) { (pointer) -> kern_return_t in
            return host_info(mach_host_self(), HOST_BASIC_INFO, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return Double(data.max_mem) / gigaByte
    }
    
    private var vmStatistics64: vm_statistics64 {
        var size: mach_msg_type_number_t = hostVmInfo64Count
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { (pointer) -> kern_return_t in
            return host_statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    
    public var info: AKMemoryInfo {
        let maxMem = maxMemory
        let load = vmStatistics64

        let active      = Double(load.active_count) * Double(PAGE_SIZE) / gigaByte
        let speculative = Double(load.speculative_count) * Double(PAGE_SIZE) / gigaByte
        let inactive    = Double(load.inactive_count) * Double(PAGE_SIZE) / gigaByte
        let wired       = Double(load.wire_count) * Double(PAGE_SIZE) / gigaByte
        let compressed  = Double(load.compressor_page_count) * Double(PAGE_SIZE) / gigaByte
        let purgeable   = Double(load.purgeable_count) * Double(PAGE_SIZE) / gigaByte
        let external    = Double(load.external_page_count) * Double(PAGE_SIZE) / gigaByte
        
        let using       = active + inactive + speculative + wired + compressed - purgeable - external
        let percentage  = min(99.9, round(1000.0 * using / maxMem) / 10.0)
        let pressure    = 100.0 * (wired + compressed) / maxMem
        let app         = using - wired - compressed
        
        return AKMemoryInfo(percentage,
                            round(10.0 * pressure) / 10.0,
                            round(10.0 * app) / 10.0,
                            round(10.0 * wired) / 10.0,
                            round(10.0 * compressed) / 10.0)
    }
    
}



