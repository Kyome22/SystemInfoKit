#if os(macOS)
import Foundation
import IOKit

struct BatteryRepository: SystemRepository {
    private var ioKitClient: IOKitClient
    private var stateClient: StateClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        ioKitClient = dependencies.ioKitClient
        stateClient = dependencies.stateClient
        self.language = language
    }

    func update() async {
        // Open Connection
        let service = ioKitClient.getMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return }
        defer {
            _ = ioKitClient.close(service)
            _ = ioKitClient.release(service)
        }

        // Read Dictionary Data
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard ioKitClient.registryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, .zero) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject] else {
            return
        }
        props?.release()

        guard let installed = dict["BatteryInstalled"] as? Int else { return }

        var result = BatteryInfo(isInstalled: installed == 1, language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.batteryInfo = result }
        }

        if let currentCapacity = dict["AppleRawCurrentCapacity"] as? Double,
           let maxCapacity = dict["AppleRawMaxCapacity"] as? Double,
           let designCapacity = dict["DesignCapacity"] as? Double {
            result.percentage = .init(rawValue: min(currentCapacity / maxCapacity, 1), width: 5, language: language)
            result.maxCapacity = .init(rawValue: min(maxCapacity / designCapacity, 1), width: 5, language: language)
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
            result.temperature = .init(value: temperature / 100.0, language: language)
        }
    }

    func reset() {
        stateClient.withLock { $0.bundle.batteryInfo = nil }
    }
}
#elseif os(iOS)
import UIKit

struct BatteryRepository: SystemRepository {
    private var stateClient: StateClient
    private var uiDeviceClient: UIDeviceClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        stateClient = dependencies.stateClient
        uiDeviceClient = dependencies.uiDeviceClient
        self.language = language
    }

    func update() async {
        await MainActor.run {
            uiDeviceClient.setIsBatteryMonitoringEnabled(true)
        }

        var result = BatteryInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.batteryInfo = result }
        }

        let batteryLevel = await MainActor.run {
            uiDeviceClient.batteryLevel()
        }
        result.percentage = .init(rawValue: Double(batteryLevel), width: 5, language: language)

        let batteryState = await MainActor.run {
            uiDeviceClient.batteryState()
        }
        result.isCharging = [.charging, .full].contains(batteryState)
    }

    func reset() {
        stateClient.withLock { $0.bundle.batteryInfo = nil }
    }
}
#endif
