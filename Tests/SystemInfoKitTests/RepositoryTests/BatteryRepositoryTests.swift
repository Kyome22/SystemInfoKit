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
                            "CurrentCapacity" : NSNumber(value: 98.2),
                            "MaxCapacity" : NSNumber(value: 100.0),
                            "IsCharging" : NSNumber(booleanLiteral: true),
                            "ExternalConnected" : NSNumber(booleanLiteral: true),
                            "AdapterDetails" : NSDictionary(dictionary: [
                                "Name" : "140W USB-C Power Adapter",
                            ]),
                            "CycleCount" : NSNumber(integerLiteral: 7),
                            "Temperature" : NSNumber(integerLiteral: 3019),
                            "BatteryData" : NSDictionary(dictionary: [
                                "CurrentCapacity" : NSNumber(value: 98.2),
                                "FullChargeCapacity" : NSNumber(integerLiteral: 5982),
                                "DesignCapacity" : NSNumber(integerLiteral: 6249),
                                "Temperature" : NSNumber(integerLiteral: 3019),
                            ]),
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
            "Power Source: 140W USB-C Power Adapter",
            "Max Capacity:  95.7%",
            "Cycle Count: 7",
            "Temperature: 30.2°C",
        ].joined(separator: "\n\t")
        #expect(actual.description == expect)
    }

    @Test
    func update_with_unidentified_adapter() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(
            .testDependencies(
                ioKitClient: testDependency(of: IOKitClient.self) {
                    $0.getMatchingService = { _, _ in 1 }
                    $0.registryEntryCreateCFProperties = { _, pointer, _, _ in
                        let dict = NSMutableDictionary(dictionary: [
                            "BatteryInstalled" : NSNumber(booleanLiteral: true),
                            "ExternalConnected" : NSNumber(booleanLiteral: true),
                            "AdapterDetails" : NSDictionary(dictionary: [
                                "Watts" : NSNumber(integerLiteral: 90),
                            ]),
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
        #expect(actual.details.first == "Power Source: 90W Power Adapter")
    }

    @Test
    func update_on_battery() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(
            .testDependencies(
                ioKitClient: testDependency(of: IOKitClient.self) {
                    $0.getMatchingService = { _, _ in 1 }
                    $0.registryEntryCreateCFProperties = { _, pointer, _, _ in
                        let dict = NSMutableDictionary(dictionary: [
                            "BatteryInstalled" : NSNumber(booleanLiteral: true),
                            "ExternalConnected" : NSNumber(booleanLiteral: false),
                            "AdapterDetails" : NSDictionary(dictionary: [
                                "FamilyCode" : NSNumber(integerLiteral: 0),
                            ]),
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
        #expect(actual.details.first == "Power Source: Battery")
    }

    @Test
    func update_with_adapter_missing_details() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = BatteryRepository(
            .testDependencies(
                ioKitClient: testDependency(of: IOKitClient.self) {
                    $0.getMatchingService = { _, _ in 1 }
                    $0.registryEntryCreateCFProperties = { _, pointer, _, _ in
                        let dict = NSMutableDictionary(dictionary: [
                            "BatteryInstalled" : NSNumber(booleanLiteral: true),
                            "ExternalConnected" : NSNumber(booleanLiteral: true),
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
        #expect(actual.details.first == "Power Source: Unknown")
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
    func update_releases_every_io_service_exactly_once() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let matchedServices = OSAllocatedUnfairLock<[io_service_t]>(initialState: [])
        let releasedObjects = OSAllocatedUnfairLock<[io_object_t]>(initialState: [])
        let sut = BatteryRepository(
            .testDependencies(
                ioKitClient: testDependency(of: IOKitClient.self) {
                    $0.getMatchingService = { _, _ in
                        matchedServices.withLock { services in
                            let service = io_service_t(services.count + 1)
                            services.append(service)
                            return service
                        }
                    }
                    $0.release = { object in
                        releasedObjects.withLock { objects in objects.append(object) }
                        return kIOReturnSuccess
                    }
                    $0.registryEntryCreateCFProperties = { _, pointer, _, _ in
                        let dict = NSMutableDictionary(dictionary: [
                            "BatteryInstalled" : NSNumber(booleanLiteral: true),
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
        #expect(releasedObjects.withLock(\.self) == matchedServices.withLock(\.self))
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
