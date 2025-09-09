#if os(iOS)
import UIKit

struct UIDeviceClient: DependencyClient {
    var setIsBatteryMonitoringEnabled: @MainActor @Sendable (Bool) -> Void
    var batteryLevel: @MainActor @Sendable () -> Float
    var batteryState: @MainActor @Sendable () -> UIDevice.BatteryState

    static let liveValue = Self(
        setIsBatteryMonitoringEnabled: { UIDevice.current.isBatteryMonitoringEnabled = $0 },
        batteryLevel: { UIDevice.current.batteryLevel },
        batteryState: { UIDevice.current.batteryState }
    )

    static let testValue = Self(
        setIsBatteryMonitoringEnabled: { _ in },
        batteryLevel: { .zero },
        batteryState: { .unknown }
    )
}
#else
struct UIDeviceClient: DependencyClient {
    static let liveValue = Self()
    static let testValue = Self()
}
#endif
