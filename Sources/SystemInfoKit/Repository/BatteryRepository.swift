import IOKit

struct BatteryRepository: Sendable {
    var current = BatteryInfo(isInstalled: false)

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

#if arch(x86_64) // Intel chip
        if let designCapacity = dict["DesignCapacity"] as? Double,
           let maxCapacity = dict["MaxCapacity"] as? Double,
           let currentCapacity = dict["CurrentCapacity"] as? Double {
            result.value = (100.0 * currentCapacity / maxCapacity).round2dp
            result.healthValue = (100.0 * maxCapacity / designCapacity).round2dp
        }
#elseif arch(arm64) // Apple Silicon chip
        if let designCapacity = dict["DesignCapacity"] as? Double,
           let nominalCapacity = dict["NominalChargeCapacity"] as? Double,
           let currentCapacity = dict["CurrentCapacity"] as? Double {
            result.value = currentCapacity
            result.maxCapacityValue = min((100.0 * nominalCapacity / designCapacity).round2dp, 100.0)
        }
#endif
        if let isCharging = dict["IsCharging"] as? Int {
            result.isCharging = isCharging == 1
        }
        if let adapter = dict["AdapterDetails"] as? [String: AnyObject],
           let name = adapter["Name"] as? String {
            result.adapterName = name
        }
        if let cycleCount = dict["CycleCount"] as? Int {
            result.cycleValue = cycleCount
        }
        if let temperature = dict["Temperature"] as? Double {
            result.temperatureValue = temperature / 100.0
        }
        current = result
    }

    mutating func reset() {
        current = BatteryInfo(isInstalled: false)
    }
}
