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
    
    var observer: ActivityObserver!

    override func setUp() {
        observer = ActivityObserver(interval: 5.0)
    }

    override func tearDown() {

    }
    
    func testAll() {
        Swift.print(observer.statistics)
    }

    func testCPU() {
        Swift.print(observer.cpuDescription)
    }
    
    func testMemory() {
        Swift.print(observer.memoryDescription)
    }
    
    func testDisk() {
        Swift.print(observer.diskDescription)
    }
    
    func testNetwork() {
        Swift.print(observer.networkDescription)
        sleep(5)
        Swift.print(observer.networkDescription)
    }

    func testPerformanceExample() {
        measure {
        }
    }

}
