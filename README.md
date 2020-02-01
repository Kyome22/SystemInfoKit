# ActivityKit

ActivityKit provides macOS system information.

- CPU usage
- Memory performance
- Disk capacity
- Network connection

This framework is written in Swift 5.

## Installation

### CocoaPods
ActivityKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ActivityKit'
```

### Carthage
ActivityKit is also available through [Carthage](https://github.com/Carthage/Carthage)

```
github "Kyome22/ActivityKit"
```

## Usage

```swift
import ActivityKit

// get all statistics per 5 seconds
var observer = ActivityObserver(interval: 5.0)

Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { (t) in
    print(observer.statistics)
}

// example output
// CPU usage: 16.0%, system: 4.8%, user: 11.2%, idle: 84.0%
// Memory performance: 79.5%, pressure: 35.1%, app: 7.1 GB, wired: 2.9 GB, compressed: 2.7 GB
// Disk capacity: 42.6%, total: 920 GB, free: 528 GB, used: 392 GB
// Network: Wi-Fi, Local IP: xx.x.x.xx, upload: 3.1 KB/s, download: 20.0 KB/s
```

**CPU usage**

```swift
print(observer.cpuDescription)

// example output
// CPU usage: 16.0%, system: 4.8%, user: 11.2%, idle: 84.0%

// You can get detailed raw values
let usage = observer.cpuUsage
// usage.percentage
// usage.system
// usage.user
// usage.idle
```

**Memory performance**

```swift
print(observer.memoryDescription)

// example output
// Memory performance: 79.5%, pressure: 35.1%, app: 7.1 GB, wired: 2.9 GB, compressed: 2.7 GB

// You can get detailed raw values
let performance = observer.memoryPerformance
// performance.percentage
// performance.pressure
// performance.app
// performance.wired
// performance.compressed
```

**Disk capacity**

```swift
print(observer.diskDescription)

// example output
// Disk capacity: 42.6%, total: 920 GB, free: 528 GB, used: 392 GB

// You can get detailed raw values
let capacity = observer.diskCapacity
// capacity.percentage
// capacity.total
// capacity.free
// capacity.used
```

**Network connection**

```swift
print(observer.networkDescription)

// example output
// Network: Wi-Fi, Local IP: xx.x.x.xx, upload: 3.1 KB/s, download: 20.0 KB/s

// You can get detailed raw values
let connection = observer.networkConnection
// connection.name
// connection.localIP
// connection.upload
// connection.download
```

## Copyright and License

Copyright 2020 Takuto Nakamura

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
