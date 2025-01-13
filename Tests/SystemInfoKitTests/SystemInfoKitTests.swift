@testable import SystemInfoKit
import XCTest
import Combine

final class SystemInfoKitTests: XCTestCase {
    @MainActor
    func test_statistics() {
        let observer = SystemInfoObserver.shared(monitorInterval: 3.0)
        var cnt = 0
        let expect = expectation(description: "systemInfo")
        let task = Task {
            for await systemInfoBundle in observer.systemInfoStream {
                Swift.print(systemInfoBundle)
                cnt += 1
                if cnt == 3 {
                    expect.fulfill()
                }
            }
        }
        observer.startMonitoring()
        waitForExpectations(timeout: 7.0)
        observer.stopMonitoring()
        task.cancel()
    }
}
