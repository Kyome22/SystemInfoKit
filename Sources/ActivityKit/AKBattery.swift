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
import IOKit.ps

public struct AKBatteryInfo {

    public var percentage: Double = 0.0
    public var powerSource: String = "Unknown"
    public var health: Double = 0.0
    public var cycle: Int = 0
    public var temperature: Double = 0.0

    init() {}

    init(percentage: Double, powerSource: String, health: Double, cycle: Int, temperature: Double) {
        self.percentage = percentage
        self.powerSource = powerSource
        self.health = health
        self.cycle = cycle
        self.temperature = temperature
    }

    public var description: String {
        let format = """
        Battery
            Charged: %.1f%%
            Power Source: %@
            Health: %.1f%%
            Cycle: %d
            Temperature: %.1f°C
        """
        return String(format: format, percentage, powerSource, health, cycle, temperature)
    }

}

final public class AKBattery {

    public internal(set) var current = AKBatteryInfo()

    var service: io_service_t = 0

    private func open() -> kern_return_t {
        if service != 0 {
            return kIOReturnStillOpen
        }
        service = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceNameMatching("AppleSmartBattery")
        )
        if service == 0 {
            return kIOReturnNotFound
        }
        return kIOReturnSuccess
    }

    private func close() {
        IOServiceClose(service)
        IOObjectRelease(service)
        service = 0
    }

    public func update() {
        var result = AKBatteryInfo()
        defer {
            close()
            current = result
        }
        if open() != kIOReturnSuccess { return }
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject]
        else { return }
        if let designCapacity = dict["DesignCapacity"] as? Double,
           let maxCapacity = dict["MaxCapacity"] as? Double,
           let currentCapacity = dict["CurrentCapacity"] as? Double {
            result.percentage = 100.0 * currentCapacity / maxCapacity
            result.health = 100.0 * maxCapacity / designCapacity
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
