import Foundation
import Testing

@testable import SystemInfoKit

struct SystemInfoObserverTests {
    @Test
    func test_statistics() async {
        let observer = SystemInfoObserver.shared(monitorInterval: 3.0)
        let task = Task {
            var count = 0
            for await systemInfoBundle in observer.systemInfoStream() {
                Swift.print(systemInfoBundle)
                count += 1
                if count == 2 {
                    break
                }
            }
        }
        defer { task.cancel() }
        observer.startMonitoring()
        await task.value
        observer.stopMonitoring()
    }
}
