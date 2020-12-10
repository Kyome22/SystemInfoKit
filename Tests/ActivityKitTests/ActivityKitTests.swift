import XCTest
@testable import ActivityKit


final class ActivityKitTests: XCTestCase {

    let observer = ActivityObserver()

    override func tearDown() {
        super.tearDown()
        observer.stop()
    }

    func testStatistics() {
        Swift.print(observer.statistics)
        var cnt = 0
        let expect = expectation(description: "called update()")
        observer.updatedStatisticsHandler = { _ in
            cnt += 1
            if cnt == 2 {
                expect.fulfill()
            }
        }
        observer.start(interval: 3.0)
        waitForExpectations(timeout: 7.0) { [weak self] (error) in
            if let error = error {
                XCTFail("Did not call update(), \(error.localizedDescription)")
            }
            if let self = self {
                Swift.print()
                Swift.print(self.observer.statistics)
            }
        }
    }

    static var allTests = [
        ("testStatistics", testStatistics),
    ]

}
