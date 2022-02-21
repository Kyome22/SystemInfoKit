import XCTest
@testable import ActivityKit


final class ActivityKitTests: XCTestCase {

    let observer = ActivityObserver()

    override func tearDown() {
        super.tearDown()
        observer.stop()
    }

    func testStatistics() {
        var cnt = 0
        let expect = expectation(description: "called update()")
        observer.updatedStatisticsHandler = { observer in
            Swift.print(observer.statistics)
            cnt += 1
            if cnt == 2 {
                expect.fulfill()
            }
        }
        observer.start(interval: 3.0)
        waitForExpectations(timeout: 7.0) { [observer] (error) in
            observer.stop()
            if let error = error {
                XCTFail("Did not call update(), \(error.localizedDescription)")
            }
        }
    }

    static var allTests = [
        ("testStatistics", testStatistics),
    ]

}
