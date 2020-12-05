//
//  ActivityKitTests.swift
//  ActivityKitTests
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright 2020 Takuto Nakamura
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import ActivityKit

class ActivityKitTests: XCTestCase {
    
    let observer = ActivityObserver()

    override func setUp() {
        super.setUp()
    }

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

}
