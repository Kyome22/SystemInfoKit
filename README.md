# ActivityKit

ActivityKit provides macOS system information.

- CPU usage
- Memory performance
- Battery state
- Disk capacity
- Network connection

This framework is written in Swift 5.

## Installation

ActivityKit supports CocoaPods and Swift Package Manager.

## Usage

```swift
import ActivityKit

// get all statistics per 3 seconds
let observer = ActivityObserver()
observer.updatedStatisticsHandler = { observer in
    Swift.print(observer.statistics)
}
observer.start(interval: 3.0)

// finish to get statistics
observer.stop()
```

## Sample Output

```console
CPU
    Usage: 16.1%
    System: 5.9%
    User: 10.2%
    Idle: 83.9%
Memory
    Performance: 79.0%
    Pressure: 45.6%
    App: 5.3 GB
    Wired: 4.3 GB
    Compressed: 3.0 GB
Battery
    Charged: 99.6%
    Power Source: Unknown
    Health: 89.9%
    Cycle: 31
    Tempreture: 31.1℃
Disk
    Capacity: 43.2%
    Total: 950.2 GB
    Free: 539.9 GB
    Used: 410.4 GB
Network
    Name Wi-Fi
    Local IP: xx.x.x.xx
    Upload: 4.0 KB/s
    Download: 6.3 KB/s
```

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
