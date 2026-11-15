import Network

struct NWPathMonitorClient: DependencyClient {
    var start: @Sendable (NWPathMonitor, DispatchQueue) -> Void
    var cancel: @Sendable (NWPathMonitor) -> Void
    var currentStatus: @Sendable (NWPathMonitor) -> NWPath.Status
    var currentAvailableInterfaceTypes: @Sendable (NWPathMonitor) -> [NWInterface.InterfaceType]
    var currentAvailableInterfaceNames: @Sendable (NWPathMonitor) -> [String]

    static let liveValue = Self(
        start: { $0.start(queue: $1) },
        cancel: { $0.cancel() },
        currentStatus: { $0.currentPath.status },
        currentAvailableInterfaceTypes: { $0.currentPath.availableInterfaces.map(\.type) },
        currentAvailableInterfaceNames: { $0.currentPath.availableInterfaces.map(\.name) }
    )

    static let testValue = Self(
        start: { _, _ in },
        cancel: { _ in },
        currentStatus: { _ in NWPath.Status.unsatisfied },
        currentAvailableInterfaceTypes: { _ in [] },
        currentAvailableInterfaceNames: { _ in [] }
    )
}
