# SystemInfoKit

SystemInfoKit provides macOS/iOS system information.

- CPU Usage
- Memory Pressure
- Storage Capacity
- Battery Status
- Network Connectivity

## Requirements

- Development with Xcode 26.3+
- Written in Swift 6.2
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

### Broadcasting to multiple consumers

`systemInfoStream()` returns a single-consumer `AsyncStream`. If two `for await` loops iterate the same stream, they will compete for values rather than each receiving every update. SystemInfoKit intentionally does not own the multi-broadcast concern — wrap the stream with [`swift-async-algorithms`](https://github.com/apple/swift-async-algorithms)' `share()` on the consumer side.

```swift
import AsyncAlgorithms
import SystemInfoKit

let observer = SystemInfoObserver.shared
let shared = observer.systemInfoStream().share()

Task {
    for await systemInfoBundle in shared {
        Swift.print("subscriber A:", systemInfoBundle)
    }
}
Task {
    for await systemInfoBundle in shared {
        Swift.print("subscriber B:", systemInfoBundle)
    }
}
observer.startMonitoring(monitorInterval: 3.0)
```

### Reading the latest snapshot synchronously

If you only need the most recent values without subscribing to the stream, use `currentSystemInfo`:

```swift
let snapshot = observer.currentSystemInfo
Swift.print(snapshot.cpuInfo, snapshot.memoryInfo)
```

Fields corresponding to a `SystemInfoType` that has not yet been updated (or has been disabled via `toggleActivation`) remain `nil`.

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
- Russian
- Spanish
- Vietnamese

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
