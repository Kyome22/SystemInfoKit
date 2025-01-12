@testable import SystemInfoKit
import XCTest
import Combine

final class SystemInfoKitTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        super.tearDown()
        cancellables.removeAll()
    }

    @MainActor
    func testStatistics() {
        let observer = SystemInfoObserver.shared(monitorInterval: 3.0)
        var cnt = 0
        let expect = expectation(description: "systemInfo")

        observer.systemInfoPublisher
            .sink { systemInfoBundle in
                Swift.print(systemInfoBundle)
                cnt += 1
                if cnt == 3 {
                    expect.fulfill()
                }
            }
            .store(in: &cancellables)

        observer.startMonitoring()

        waitForExpectations(timeout: 7.0) { [observer] (error) in
            observer.stopMonitoring()
            if let error = error {
                XCTFail("Did not get systemInfo, \(error.localizedDescription)")
            }
        }
    }
}
