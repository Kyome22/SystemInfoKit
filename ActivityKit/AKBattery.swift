//
//  AKBattery.swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/12/05.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

import IOKit
import IOKit.ps

public struct AKBatteryInfo {

    public var percentage: Double = 0.0
    public var powerSource: String = "Unknown"
    public var health: Double = 0.0
    public var cycle: Int = 0
    public var tempreture: Double = 0.0

    init() {}

    init(percentage: Double, powerSource: String, health: Double, cycle: Int, tempreture: Double) {
        self.percentage = percentage
        self.powerSource = powerSource
        self.health = health
        self.cycle = cycle
        self.tempreture = tempreture
    }

    public var description: String {
        let format = """
        Battery
            Charged: %.1f%%
            Power Source: %@
            Health: %.1f%%
            Cycle: %d
            Tempreture: %.1f℃
        """
        return String(format: format, percentage, powerSource, health, cycle, tempreture)
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
            result.tempreture = temperature / 100.0
        }
    }

}
