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

    private func fetchIOServiceProperties(name: String) -> [String: AnyObject]? {
        // Open Connection
        let service = ioKitClient.getMatchingService(kIOMainPortDefault, IOServiceNameMatching(name))
        guard service != IO_OBJECT_NULL else {
            return nil
        }
        defer {
            _ = ioKitClient.close(service)
            _ = ioKitClient.release(service)
        }
        // Read Dictionary Data
        var props: Unmanaged<CFMutableDictionary>? = nil
        guard ioKitClient.registryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, .zero) == kIOReturnSuccess,
              let dict = props?.takeUnretainedValue() as? [String: AnyObject] else {
            return nil
        }
        props?.release()
        return dict
    }

    func update() async {
        guard let batteryDict = fetchIOServiceProperties(name: "AppleSmartBattery"),
              let installed = batteryDict["BatteryInstalled"] as? Int,
              let batteryPackDict = fetchIOServiceProperties(name: "AppleSmartBatteryPack") else {
            return
        }

        var result = BatteryInfo(isInstalled: installed == 1, language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.batteryInfo = result }
        }

        if #available(macOS 27.0, *) {
            if let batteryData = batteryDict["BatteryData"] as? [String: AnyObject],
               let currentCapacity = batteryData["CurrentCapacity"] as? Double,
               let maxCapacity = batteryData["MaxCapacity"] as? Double
            {
                result.percentage = .init(rawValue: currentCapacity / 100, width: 5, language: language)
                result.maxCapacity = .init(rawValue: maxCapacity / 100, width: 5, language: language)
            }
            if let batteryData = batteryPackDict["BatteryData"] as? [String: AnyObject],
                let temperature = batteryData["Temperature"] as? Double {
                result.temperature = .init(value: temperature / 100.0, language: language)
            }
        } else {
            if let currentCapacity = batteryDict["AppleRawCurrentCapacity"] as? Double,
               let maxCapacity = batteryDict["AppleRawMaxCapacity"] as? Double,
               let designCapacity = batteryDict["DesignCapacity"] as? Double {
                result.percentage = .init(rawValue: min(currentCapacity / maxCapacity, 1), width: 5, language: language)
                result.maxCapacity = .init(rawValue: min(maxCapacity / designCapacity, 1), width: 5, language: language)
            }
            if let temperature = batteryDict["Temperature"] as? Double {
                result.temperature = .init(value: temperature / 100.0, language: language)
            }
        }

        if let isCharging = batteryDict["IsCharging"] as? Int {
            result.isCharging = isCharging == 1
        }
        if let adapter = batteryDict["AdapterDetails"] as? [String: AnyObject],
           let name = adapter["Name"] as? String {
            result.adapterName = name
        }
        if let cycleCount = batteryDict["CycleCount"] as? Int {
            result.cycleCount = cycleCount
        }
    }

    func setInitial() {
        stateClient.withLock {
            $0.bundle.batteryInfo = .init(language: language)
        }
    }

    func reset() {
        stateClient.withLock {
            $0.bundle.batteryInfo = nil
        }
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
        await uiDeviceClient.setIsBatteryMonitoringEnabled(true)
        
        var result = BatteryInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.batteryInfo = result }
        }

        let batteryLevel = await uiDeviceClient.batteryLevel()
        result.percentage = .init(rawValue: Double(batteryLevel), width: 5, language: language)

        let batteryState = await uiDeviceClient.batteryState()
        result.isCharging = [.charging, .full].contains(batteryState)
    }

    func setInitial() {
        stateClient.withLock {
            $0.bundle.batteryInfo = .init(language: language)
        }
    }

    func reset() {
        stateClient.withLock {
            $0.bundle.batteryInfo = nil
        }
    }
}
#endif
