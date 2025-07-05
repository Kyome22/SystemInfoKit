# SystemInfoKit

SystemInfoKit provides macOS system information.

- CPU usage
- Memory performance
- Storage capacity
- Battery state
- Network connection

## Requirements

- Development with Xcode 16.4+
- Written in Swift 6.1
- Compatible with macOS 13.0+

## Installation

SystemInfoKit supports Swift Package Manager.

## Usage

```swift
import SystemInfoKit

// Get all system info per 3 seconds
let observer = SystemInfoObserver.shared(monitorInterval: 3.0)

Task {
    for await systemInfoBundle in observer.systemInfoStream() {
        Swift.print(systemInfoBundle)
    }
}
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
Storage: 58.7% used
    584.13 GB / 994.66 GB
Battery: not installed
    Power Source: Unknown
    Max Capacity:   0.0%
    Cycle Count: 0
    Temperature:  0.0℃
Network: Ethernet
    Local IP: 192.0.2.1
    Upload:  50.7 KB/s
    Download:   1.7 KB/s
```

## Supported languages

- English (primary)
- Japanese
- Korean

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
