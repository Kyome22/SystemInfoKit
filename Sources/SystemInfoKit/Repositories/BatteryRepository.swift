import IOKit

struct BatteryRepository: Sendable {
    private var systemInfoStateClient: SystemInfoStateClient

    init(_ systemInfoStateClient: SystemInfoStateClient) {
        self.systemInfoStateClient = systemInfoStateClient
    }

    func update() {
        // Open Connection
        let service: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        guard service != MACH_PORT_NULL else { return }
        defer {
            IOServiceClose(service)
            IOObjectRelease(service)
        }

        // Read Dictionary Data
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject] else {
            return
        }
        props?.release()

        guard let installed = dict["BatteryInstalled"] as? Int else { return }

        var result = BatteryInfo(isInstalled: installed == 1)
        defer {
            systemInfoStateClient.withLock { [result] in $0.bundle.batteryInfo = result }
        }

        if let designCapacity = dict["DesignCapacity"] as? Double,
           let maxCapacity = dict["AppleRawMaxCapacity"] as? Double,
           let currentCapacity = dict["AppleRawCurrentCapacity"] as? Double {
            result.percentage = .init(rawValue: min(currentCapacity / maxCapacity, 1), width: 5)
            result.maxCapacity = .init(rawValue: min(maxCapacity / designCapacity, 1), width: 5)
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
    }

    func reset() {
        systemInfoStateClient.withLock { $0.bundle.batteryInfo = .init(isInstalled: false) }
    }
}
