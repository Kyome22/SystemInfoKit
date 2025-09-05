import Foundation
import IOKit
import os
import Testing

@testable import SystemInfoKit

struct BatteryRepositoryTests {
    @Test
    func update_with_battery() throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(.testDependencies(
            ioKitClient: testDependency(of: IOKitClient.self) {
                $0.getMatchingService = { _, _ in 1 }
                $0.registryEntryCreateCFProperties = { _, pointer, _, _ in
                    let dict = NSMutableDictionary(dictionary: [
                        "BatteryInstalled" : NSNumber(booleanLiteral: true),
                        "DesignCapacity" : NSNumber(integerLiteral: 6249),
                        "AppleRawMaxCapacity" : NSNumber(integerLiteral: 5982),
                        "AppleRawCurrentCapacity" : NSNumber(integerLiteral: 5873),
                        "IsCharging" : NSNumber(booleanLiteral: true),
                        "AdapterDetails" : NSDictionary(dictionary: ["Name" : "SomeAdapter"]),
                        "CycleCount" : NSNumber(integerLiteral: 7),
                        "Temperature" : NSNumber(integerLiteral: 3019),
                    ])
                    pointer?.pointee = Unmanaged.passRetained(dict)
                    return kIOReturnSuccess
                }
            },
            stateClient: .testDependency(state)
        ))
        sut.update()
        let actual = try #require({ state.withLock(\.bundle.batteryInfo) }())
        let expect = [
            "Battery:  98.2%",
            "Power Source: SomeAdapter",
            "Max Capacity:  95.7%",
            "Cycle Count: 7",
            "Temperature: 30.2°C",
        ].joined(separator: "\n\t")
        #expect(actual.description == expect)
    }

    @Test
    func update_without_battery() throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(.testDependencies(
            ioKitClient: testDependency(of: IOKitClient.self) {
                $0.getMatchingService = { _, _ in 1 }
                $0.registryEntryCreateCFProperties = { _, pointer, _, _ in
                    let dict = NSMutableDictionary(dictionary: [
                        "BatteryInstalled" : NSNumber(booleanLiteral: false),
                        "IsCharging" : NSNumber(booleanLiteral: false),
                        "CycleCount" : NSNumber(integerLiteral: 0),
                    ])
                    pointer?.pointee = Unmanaged.passRetained(dict)
                    return kIOReturnSuccess
                }
            },
            stateClient: .testDependency(state)
        ))
        sut.update()
        let actual = try #require({ state.withLock(\.bundle.batteryInfo) }())
        #expect(actual.description == "Battery: Not Installed")
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.batteryInfo = .init(
                percentage: .init(rawValue: 0.982),
                isInstalled: true,
                isCharging: false,
                maxCapacity: .init(rawValue: 0.957),
                cycleCount: 7,
                temperature: 3020
            )
        }
        let sut = BatteryRepository(.testDependencies(stateClient: .testDependency(state)))
        sut.reset()
        #expect(state.withLock(\.bundle.batteryInfo)?.description == "Battery: Not Installed")
    }
}
