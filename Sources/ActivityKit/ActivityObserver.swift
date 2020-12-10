//
//  ActivityObserver..swift
//  ActivityKit
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

import Foundation

final public class ActivityObserver {

    private let cpu = AKCPU()
    private let memory = AKMemory()
    private let disk = AKDisk()
    private let network = AKNetwork()
    private let battery = AKBattery()
    private var timer: Timer?

    public var updatedStatisticsHandler: ((_ observer: ActivityObserver) -> Void)?

    public init() {}

    deinit {
        timer?.invalidate()
    }

    public func update(interval: Double) {
        cpu.update()
        memory.update()
        disk.update()
        network.update(interval: interval)
        battery.update()
        updatedStatisticsHandler?(self)
    }

    public func start(interval: Double) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
            self?.update(interval: interval)
        })
        RunLoop.main.add(timer!, forMode: RunLoop.Mode.common)
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    public var statistics: String {
        let info: [String] = [
            cpu.current.description,
            memory.current.description,
            battery.current.description,
            disk.current.description,
            network.current.description
        ]
        return info.joined(separator: "\n")
    }
    
    public var cpuUsage: AKCPUInfo {
        return cpu.current
    }
    
    public var cpuDescription: String {
        return cpu.current.description
    }
    
    public var memoryPerformance: AKMemoryInfo {
        return memory.current
    }
    
    public var memoryDescription: String {
        return memory.current.description
    }

    public var batteryStatus: AKBatteryInfo {
        return battery.current
    }

    public var batteryDescription: String {
        return battery.current.description
    }
    
    public var diskCapacity: AKDiskInfo {
        return disk.current
    }

    public var diskDescription: String {
        return disk.current.description
    }

    public var networkConnection: AKNetworkInfo {
        return network.current
    }
    
    public var networkDescription: String {
        return network.current.description
    }
    
}
