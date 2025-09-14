import Foundation
import os
import Testing

@testable import SystemInfoKit

struct SystemInfoObserverTests {
    @Test
    func ovservation() async {
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
    func toggleActivation() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.activationState = [.cpu: true, .memory: false, .storage: true, .battery: false, .network: true]
        }
        let observer = SystemInfoObserver(
            dependencies: .testDependencies(stateClient: .testDependency(state)),
            language: .english
        )
        observer.toggleActivation(requests: [.cpu: false, .memory: true])
        let actual = state.withLock(\.activationState)
        #expect(actual == [.cpu: false, .memory: true, .storage: true, .battery: false, .network: true])
    }
}
