import Foundation
import Network
import os
import Testing

@testable import SystemInfoKit

struct SystemInfoObserverTests {
    @Test
    func observation() async {
        let observer = SystemInfoObserver(dependencies: .init(), language: .english)
        let task = Task {
            var count = 0
            for await systemInfoBundle in observer.systemInfoStream() {
                Swift.print(systemInfoBundle, "\n")
                count += 1
                if count == 2 {
                    break
                }
            }
        }
        observer.startMonitoring(monitorInterval: 3.0)
        await task.value
        observer.stopMonitoring()
    }

    @Test
    func restartMonitoring_starts_fresh_path_monitor() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let startedPathMonitors = OSAllocatedUnfairLock<[NWPathMonitor]>(uncheckedState: [])
        let cancelledPathMonitors = OSAllocatedUnfairLock<[NWPathMonitor]>(uncheckedState: [])
        let observer = SystemInfoObserver(
            dependencies: .testDependencies(
                nwPathMonitorClient: testDependency(of: NWPathMonitorClient.self) {
                    $0.start = { pathMonitor, _ in
                        startedPathMonitors.withLockUnchecked { $0.append(pathMonitor) }
                    }
                    $0.cancel = { pathMonitor in
                        cancelledPathMonitors.withLockUnchecked { $0.append(pathMonitor) }
                    }
                },
                stateClient: .testDependency(state)
            ),
            language: .english
        )
        observer.startMonitoring()
        observer.stopMonitoring()
        #expect(state.withLock { $0.pathMonitor == nil })
        observer.startMonitoring()
        observer.stopMonitoring()
        let started = startedPathMonitors.withLockUnchecked(\.self)
        let cancelled = cancelledPathMonitors.withLockUnchecked(\.self)
        #expect(started.count == 2)
        #expect(started.first !== started.last)
        #expect(cancelled.count == 2)
        #expect(zip(started, cancelled).allSatisfy { $0 === $1 })
    }

    @Test
    func toggleActivation() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.activationState = [.cpu: true, .memory: false, .storage: true, .battery: false, .network: true]
            $0.bundle.cpuInfo = .zero
            $0.bundle.storageInfo = .zero
        }
        let observer = SystemInfoObserver(
            dependencies: .testDependencies(stateClient: .testDependency(state)),
            language: .english
        )
        observer.toggleActivation(requests: [.cpu: false, .memory: true, .storage: true])
        let actualActivation = state.withLock(\.activationState)
        #expect(actualActivation == [.cpu: false, .memory: true, .storage: true, .battery: false, .network: true])
        #expect(state.withLock(\.bundle.cpuInfo) == nil)
        #expect(state.withLock(\.bundle.memoryInfo) != nil)
        #expect(state.withLock(\.bundle.storageInfo) != nil)
        #expect(state.withLock(\.bundle.batteryInfo) == nil)
        #expect(state.withLock(\.bundle.networkInfo) == nil)
    }
}
