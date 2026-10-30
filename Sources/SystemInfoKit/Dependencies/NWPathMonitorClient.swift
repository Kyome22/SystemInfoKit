import Network
import os

struct NWPathMonitorClient: DependencyClient {
    var start: @Sendable (DispatchQueue) -> Void
    var cancel: @Sendable () -> Void
    var currentStatus: @Sendable () -> NWPath.Status
    var currentAvailableInterfaceTypes: @Sendable () -> [NWInterface.InterfaceType]
    var currentAvailableInterfaceNames: @Sendable () -> [String]

    static let liveValue: Self = {
        let monitor = OSAllocatedUnfairLock(uncheckedState: NWPathMonitor())
        return Self(
            start: { queue in
                monitor.withLockUnchecked {
                    $0.cancel()
                    $0 = NWPathMonitor()
                    $0.start(queue: queue)
                }
            },
            cancel: { monitor.withLockUnchecked { $0.cancel() } },
            currentStatus: { monitor.withLockUnchecked { $0.currentPath.status } },
            currentAvailableInterfaceTypes: { monitor.withLockUnchecked { $0.currentPath.availableInterfaces.map(\.type) } },
            currentAvailableInterfaceNames: { monitor.withLockUnchecked { $0.currentPath.availableInterfaces.map(\.name) } }
        )
    }()

    static let testValue = Self(
        start: { _ in },
        cancel: {},
        currentStatus: { NWPath.Status.unsatisfied },
        currentAvailableInterfaceTypes: { [] },
        currentAvailableInterfaceNames: { [] }
    )
}
