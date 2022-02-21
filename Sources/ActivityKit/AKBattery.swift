//
//  AKBattery.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/12/05.
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

import IOKit

public struct AKBatteryInfo {
    
    public var installed: Bool = false
    public var percentage: Double = 0.0
    public var powerSource: String = "Unknown"
    public var maxCapacity: Double = 0.0
    public var cycle: Int = 0
    public var temperature: Double = 0.0
    
    init() {}
    
    init(
        installed: Bool,
        percentage: Double,
        powerSource: String,
        maxCapacity: Double,
        cycle: Int,
        temperature: Double
    ) {
        self.installed = installed
        self.percentage = percentage
        self.powerSource = powerSource
        self.maxCapacity = maxCapacity
        self.cycle = cycle
        self.temperature = temperature
    }
    
    public var description: String {
        if installed {
#if arch(x86_64) // Intel Chip
            let format = """
            Battery
                Charged: %.1f%%
                Power Source: %@
                Cycle: %d
                Temperature: %.1f°C
            """
            return String(format: format, percentage, powerSource, cycle, temperature)
#elseif arch(arm64) // Apple Silicon Chip
            let format = """
            Battery
                Charged: %.1f%%
                Power Source: %@
                Max Capacity: %.1f%%
                Cycle: %d
                Temperature: %.1f°C
            """
            return String(format: format, percentage, powerSource, maxCapacity, cycle, temperature)
#endif
        } else {
            return "Battery is not installed"
        }
    }
    
}

final public class AKBattery {
    
    public internal(set) var current = AKBatteryInfo()
    
    public func update() {
        var result = AKBatteryInfo()
        var service: io_service_t = 0
        
        defer {
            IOServiceClose(service)
            IOObjectRelease(service)
            current = result
        }
        
        // Open Connection
        service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                              IOServiceNameMatching("AppleSmartBattery"))
        if service == MACH_PORT_NULL { return }
        
        // Read Dictionary Data
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject]
        else { return }
        props?.release()
        
        guard let installed = dict["BatteryInstalled"] as? Int else { return }
        result.installed = (installed == 1)
                
        if let maxCapacity = dict["MaxCapacity"] as? Double,
           let currentCapacity = dict["CurrentCapacity"] as? Double {
#if arch(x86_64) // Intel Chip
            result.percentage = 100.0 * currentCapacity / maxCapacity
#elseif arch(arm64) // Apple Silicon Chip
            result.percentage = currentCapacity
            result.maxCapacity = maxCapacity
#endif
        }
        if let adapter = dict["AdapterDetails"] as? [String: AnyObject],
           let name = adapter["Name"] as? String {
            result.powerSource = name
        }
        if let cycleCount = dict["CycleCount"] as? Int {
            result.cycle = cycleCount
        }
        if let temperature = dict["Temperature"] as? Double {
            result.temperature = temperature / 100.0
        }
    }
    
}
