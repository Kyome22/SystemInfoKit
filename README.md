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
☆☆☆☆☆☆☆☆☆☆ ActivityKit Stats ☆☆☆☆☆☆☆☆☆☆
CPU
    Usage: 17.7%
    System: 4.3%
    User: 13.4%
    Idle: 82.3%
Memory
    Performance: 61.1%
    Pressure: 15.3%
    App: 14.7 GB
    Wired: 2.5 GB
    Compressed: 2.4 GB
Battery
    Charged: 100.0%
    Power Source: Unknown
    Max Capacity: 100.0%
    Cycle: 3
    Temperature: 30.3°C
Disk
    Capacity: 27.3%
    Total: 494.4 GB
    Free: 359.4 GB
    Used: 135.0 GB
Network
    Name Wi-Fi
    Local IP: xx.x.x.xx
    Upload: 10.3 KB/s
    Download: 6.3 KB/s
☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
```

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
