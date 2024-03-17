import IOKit

protocol BatteryRepository: AnyObject {
    var current: BatteryInfo { get }

    init()

    func update()
    func reset()
}

final class BatteryRepositoryImpl: BatteryRepository {
    var current = BatteryInfo()

    func update() {
        var service: io_service_t = 0

        defer {
            IOServiceClose(service)
            IOObjectRelease(service)
        }

        // Open Connection
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        if service == MACH_PORT_NULL { return }

        // Read Dictionary Data
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject]
        else { return }
        props?.release()

        guard let installed = dict["BatteryInstalled"] as? Int else { return }
        var result = BatteryInfo(installed: installed == 1)

        if let designCapacity = dict["DesignCapacity"] as? Double,
           let maxCapacity = dict["MaxCapacity"] as? Double,
           let currentCapacity = dict["CurrentCapacity"] as? Double {
#if arch(x86_64) // Intel chip
            result.value = 100.0 * currentCapacity / maxCapacity
            result.setHealthValue(100.0 * maxCapacity / designCapacity)
#elseif arch(arm64) // Apple Silicon chip
            result.value = currentCapacity
            result.setMaxCapacityValue(maxCapacity.round2dp)
#endif
        }
        if let isCharging = dict["IsCharging"] as? Int {
            result.setIsCharging(isCharging == 1)
        }
        if let adapter = dict["AdapterDetails"] as? [String: AnyObject],
           let name = adapter["Name"] as? String {
            result.setAdapterName(name)
        }
        if let cycleCount = dict["CycleCount"] as? Int {
            result.setCycleValue(cycleCount)
        }
        if let temperature = dict["Temperature"] as? Double {
            result.setTemperatureValue(temperature / 100.0)
        }
        current = result
    }

    func reset() {
        current = BatteryInfo()
    }
}

final class BatteryRepositoryMock: BatteryRepository {
    let current = BatteryInfo()
    func update() {}
    func reset() {}
}
