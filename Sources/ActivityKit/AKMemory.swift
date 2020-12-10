//
//  AKMemory.swift
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

import Darwin

public struct AKMemoryInfo {
    
    public var percentage: Double = 0.0
    public var pressure: Double = 0.0
    public var app: Double = 0.0
    public var wired: Double = 0.0
    public var compressed: Double = 0.0
    
    init() {}
    
    init(percentage: Double, pressure: Double, app: Double, wired: Double, compressed: Double) {
        self.percentage = percentage
        self.pressure = pressure
        self.app = app
        self.wired = wired
        self.compressed = compressed
    }

    public var description: String {
        let format = """
        Memory
            Performance: %.1f%%
            Pressure: %.1f%%
            App: %.1f GB
            Wired: %.1f GB
            Compressed: %.1f GB
        """
        return String(format: format, percentage, pressure, app, wired, compressed)
    }
    
}

final public class AKMemory {

    public internal(set) var current = AKMemoryInfo()

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
    
    public func update() {
        let maxMem = maxMemory
        let load = vmStatistics64

        let unit        = Double(vm_kernel_page_size) / gigaByte
        let active      = Double(load.active_count) * unit
        let speculative = Double(load.speculative_count) * unit
        let inactive    = Double(load.inactive_count) * unit
        let wired       = Double(load.wire_count) * unit
        let compressed  = Double(load.compressor_page_count) * unit
        let purgeable   = Double(load.purgeable_count) * unit
        let external    = Double(load.external_page_count) * unit
        
        let using       = active + inactive + speculative + wired + compressed - purgeable - external
        let percentage  = min(99.9, round(1000.0 * using / maxMem) / 10.0)
        let pressure    = 100.0 * (wired + compressed) / maxMem
        let app         = using - wired - compressed
        
        current = AKMemoryInfo(percentage: percentage,
                               pressure: round(10.0 * pressure) / 10.0,
                               app: round(10.0 * app) / 10.0,
                               wired: round(10.0 * wired) / 10.0,
                               compressed: round(10.0 * compressed) / 10.0)
    }
    
}



