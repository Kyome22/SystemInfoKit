import Network

struct NWPathMonitorClient: DependencyClient {
    var start: @Sendable (DispatchQueue) -> Void
    var cancel: @Sendable () -> Void
    var currentStatus: @Sendable () -> NWPath.Status
    var currentAvailableInterfaceTypes: @Sendable () -> [NWInterface.InterfaceType]
    var currentAvailableInterfaceNames: @Sendable () -> [String]

    static let liveValue: Self = {
        let monitor = NWPathMonitor()
        return Self(
            start: { monitor.start(queue: $0) },
            cancel: { monitor.cancel() },
            currentStatus: { monitor.currentPath.status },
            currentAvailableInterfaceTypes: { monitor.currentPath.availableInterfaces.map(\.type) },
            currentAvailableInterfaceNames: { monitor.currentPath.availableInterfaces.map(\.name) }
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
