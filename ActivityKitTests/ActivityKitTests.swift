//
//  ActivityKitTests.swift
//  ActivityKitTests
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
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
