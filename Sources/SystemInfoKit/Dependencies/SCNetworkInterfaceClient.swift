import SystemConfiguration

struct SCNetworkInterfaceClient: DependencyClient {
    var copyAll: @Sendable () -> CFArray
    var getBSDName: @Sendable (SCNetworkInterface) -> CFString?
    var getLocalizedDisplayName: @Sendable (SCNetworkInterface) -> CFString?

    static let liveValue = Self(
        copyAll: { SCNetworkInterfaceCopyAll() },
        getBSDName: { SCNetworkInterfaceGetBSDName($0) },
        getLocalizedDisplayName: { SCNetworkInterfaceGetLocalizedDisplayName($0) }
    )

    static let testValue = Self(
        copyAll: { [SCNetworkInterface]() as CFArray },
        getBSDName: { _ in nil },
        getLocalizedDisplayName: { _ in nil }
    )
}
