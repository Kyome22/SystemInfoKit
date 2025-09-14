import Foundation
import os
import Testing

@testable import SystemInfoKit

struct BatteryRepositoryTests {
#if os(macOS)
    @Test
    func update_with_battery() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(
            .testDependencies(
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
            ),
            language: .english
        )
        await sut.update()
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
    func update_without_battery() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(
            .testDependencies(
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
            ),
            language: .english
        )
        await sut.update()
        let actual = try #require({ state.withLock(\.bundle.batteryInfo) }())
        #expect(actual.description == "Battery: Not Installed")
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock { $0.bundle.batteryInfo = .zero }
        let sut = BatteryRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        #expect(state.withLock(\.bundle.batteryInfo) == nil)
    }
#elseif os(iOS)
    @Test
    func update() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(
            .testDependencies(
                stateClient: .testDependency(state),
                uiDeviceClient: testDependency(of: UIDeviceClient.self) {
                    $0.setIsBatteryMonitoringEnabled = { _ in }
                    $0.batteryLevel = { 0.982 }
                    $0.batteryState = { .full }
                }
            ),
            language: .english
        )
        await sut.update()
        let actual = try #require({ state.withLock(\.bundle.batteryInfo) }())
        #expect(actual.description == "Battery:  98.2%")
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock { $0.bundle.batteryInfo = .zero }
        let sut = BatteryRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        #expect(state.withLock(\.bundle.batteryInfo) == nil)
    }
#endif
}
