import IOKit

struct BatteryRepository: Sendable {
    var processor: Processor
    var current = BatteryInfo.zero

    mutating func update() {
        var service: io_service_t = 0

        defer {
            IOServiceClose(service)
            IOObjectRelease(service)
        }

        // Open Connection
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        guard service != MACH_PORT_NULL else { return }

        // Read Dictionary Data
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject] else {
            return
        }
        props?.release()

        guard let installed = dict["BatteryInstalled"] as? Int else { return }
        var result = BatteryInfo(isInstalled: installed == 1)

        switch processor {
        case .appleSilicon:
            if let designCapacity = dict["DesignCapacity"] as? Double,
               let nominalCapacity = dict["NominalChargeCapacity"] as? Double,
               let currentCapacity = dict["CurrentCapacity"] as? Double {
                result.percentage = .init(rawValue: currentCapacity, width: 5)
                result.health = .maxCapacity(.init(rawValue: nominalCapacity / designCapacity, width: 5))
            }
        case .intel:
            if let designCapacity = dict["DesignCapacity"] as? Double,
               let maxCapacity = dict["MaxCapacity"] as? Double,
               let currentCapacity = dict["CurrentCapacity"] as? Double {
                result.percentage = .init(rawValue: currentCapacity / maxCapacity, width: 5)
                result.health = .condition(.init(rawValue: maxCapacity / designCapacity, width: 5))
            }
        }

        if let isCharging = dict["IsCharging"] as? Int {
            result.isCharging = isCharging == 1
        }
        if let adapter = dict["AdapterDetails"] as? [String: AnyObject],
           let name = adapter["Name"] as? String {
            result.adapterName = name
        }
        if let cycleCount = dict["CycleCount"] as? Int {
            result.cycleCount = cycleCount
        }
        if let temperature = dict["Temperature"] as? Double {
            result.temperature = temperature / 100.0
        }
        current = result
    }

    mutating func reset() {
        current = BatteryInfo(isInstalled: false)
    }
}
