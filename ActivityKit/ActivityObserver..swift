//
//  ActivityObserver..swift
//  ActivityKit
//
//  Created by Takuto Nakamura on 2020/02/01.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

import Foundation

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
