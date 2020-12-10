//
//  AKCPU.swift
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

public struct AKCPUInfo {
    
    public var percentage: Double = 0.0
    public var system: Double = 0.0
    public var user: Double = 0.0
    public var idle: Double = 0.0
        
    init() {}
    
    init(percentage: Double, system: Double, user: Double, idle: Double) {
        self.percentage = percentage
        self.system = system
        self.user = user
        self.idle = idle
    }

    public var description: String {
        let format = """
        CPU
            Usage: %.1f%%
            System: %.1f%%
            User: %.1f%%
            Idle: %.1f%%
        """
        return String(format: format, percentage, system, user, idle)
    }
    
}

final public class AKCPU {

    public internal(set) var current = AKCPUInfo()
    
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
    
    public func update() {
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

        current = AKCPUInfo(percentage: percentage,
                            system: system,
                            user: user,
                            idle: idle)
    }
    
}
