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

final public class ActivityObserver {
    
    public let cpu: AKCPU
    public let memory: AKMemory
    public let disk: AKDisk
    public let network: AKNetwork
    
    public init(interval: Double) {
        cpu = AKCPU()
        memory = AKMemory()
        disk = AKDisk()
        network = AKNetwork(interval: interval)
    }
    
    public var statistics: String {
        var info = [String]()
        info.append(cpu.info.description)
        info.append(memory.info.description)
        info.append(disk.info.description)
        info.append(network.info.description)
        return info.joined(separator: "\n")
    }
    
    public var cpuUsage: AKCPUInfo {
        return cpu.info
    }
    
    public var cpuDescription: String {
        return cpu.info.description
    }
    
    public var memoryPerformance: AKMemoryInfo {
        return memory.info
    }
    
    public var memoryDescription: String {
        return memory.info.description
    }
    
    public var diskCapacity: AKDiskInfo {
        return disk.info
    }

    public var diskDescription: String {
        return disk.info.description
    }

    public var networkConnection: AKNetworkInfo {
        return network.info
    }
    
    public var networkDescription: String {
        return network.info.description
    }
    
}
