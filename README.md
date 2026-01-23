# SystemInfoKit

SystemInfoKit provides macOS/iOS system information.

- CPU usage
- Memory performance
- Storage capacity
- Battery state
- Network connection

## Requirements

- Development with Xcode 16.4+
- Written in Swift 6.1
- Compatible with macOS 13.0+, iOS 16.0+

## Installation

SystemInfoKit supports Swift Package Manager.

## Usage

```swift
import SystemInfoKit

// Get all system info per 3 seconds
let observer = SystemInfoObserver.shared

Task {
    for await systemInfoBundle in observer.systemInfoStream() {
        Swift.print(systemInfoBundle)
    }
}
observer.startMonitoring(monitorInterval: 3.0)

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
Storage: 58.7% used
    584.13 GB / 994.66 GB
Battery:  98.2%
    Power Source: SomeAdapter
    Max Capacity:  95.7%
    Cycle Count: 7
    Temperature: 30.2°C
Network: Ethernet
    Local IP: 192.0.2.1
    Upload:  50.7 kB/s
    Download:   1.7 kB/s
```

## Supported languages

- Chinese, Simplified
- Chinese, Traditional
- English (primary)
- French
- German
- Japanese
- Korean
- Spanish

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
