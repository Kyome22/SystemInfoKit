# SystemInfoKit

SystemInfoKit provides macOS system information.

- CPU usage
- Memory performance
- Battery state
- Storage capacity
- Network connection

## Requirements

- Development with Xcode 15.2+
- Written in Swift 5.9
- swift-tools-version: 5.9
- Compatible with macOS 12.0+

## Installation

SystemInfoKit supports Swift Package Manager.

## Usage

```swift
import SystemInfoKit
import Combine

// Get all system info per 3 seconds
let observer = SystemInfoObserver.shared(monitorInterval: 3.0)
var cancellables = Set<AnyCancellable>()

observer.systemInfoPublisher
    .sink { systemInfo in
        Swift.print(systemInfo)
    }
    .store(in: &cancellables)

observer.startMonitoring()

// Finish to get system info
observer.stopMonitoring()
```

## Sample Output

```console
CPU:  7.5%
    System:  2.9%
    User:  4.6%
    Idle: 92.5%
Memory: 72.9%
    Pressure: 33.1%
    App:  6.4 GB
    Wired:  1.8 GB
    Compressed:  3.5 GB
Battery: not installed
    Power Source: Unknown
    Max Capacity:   0.0%
    Cycle Count: 0
    Temperature:  0.0℃
Storage: 58.7% used
    584.13 GB / 994.66 GB
Network: Ethernet
    Local IP: xxx.xx.x.xxx
    Upload:  50.7 KB/s
    Download:   1.7 KB/s
```

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
