import Foundation

struct Dependencies: Sendable {
    var hostClient: HostClient
    var ioKitClient: IOKitClient
    var nwPathMonitorClient: NWPathMonitorClient
    var posixClient: POSIXClient
    var scDynamicStoreClient: SCDynamicStoreClient
    var scNetworkInterfaceClient: SCNetworkInterfaceClient
    var stateClient: StateClient
    var uiDeviceClient: UIDeviceClient
    var urlResourceValuesClient: URLResourceValuesClient

    init(
        hostClient: HostClient = .liveValue,
        ioKitClient: IOKitClient = .liveValue,
        nwPathMonitorClient: NWPathMonitorClient = .liveValue,
        posixClient: POSIXClient = .liveValue,
        scDynamicStoreClient: SCDynamicStoreClient = .liveValue,
        scNetworkInterfaceClient: SCNetworkInterfaceClient = .liveValue,
        stateClient: StateClient = .liveValue,
        uiDeviceClient: UIDeviceClient = .liveValue,
        urlResourceValuesClient: URLResourceValuesClient = .liveValue
    ) {
        self.hostClient = hostClient
        self.ioKitClient = ioKitClient
        self.nwPathMonitorClient = nwPathMonitorClient
        self.posixClient = posixClient
        self.scDynamicStoreClient = scDynamicStoreClient
        self.scNetworkInterfaceClient = scNetworkInterfaceClient
        self.stateClient = stateClient
        self.uiDeviceClient = uiDeviceClient
        self.urlResourceValuesClient = urlResourceValuesClient
    }
}

extension Dependencies {
    static func testDependencies(
        hostClient: HostClient = .testValue,
        ioKitClient: IOKitClient = .testValue,
        nwPathMonitorClient: NWPathMonitorClient = .testValue,
        posixClient: POSIXClient = .testValue,
        scDynamicStoreClient: SCDynamicStoreClient = .testValue,
        scNetworkInterfaceClient: SCNetworkInterfaceClient = .testValue,
        stateClient: StateClient = .testValue,
        uiDeviceClient: UIDeviceClient = .testValue,
        urlResourceValuesClient: URLResourceValuesClient = .testValue,
    ) -> Dependencies {
        Dependencies(
            hostClient: hostClient,
            ioKitClient: ioKitClient,
            nwPathMonitorClient: nwPathMonitorClient,
            posixClient: posixClient,
            scDynamicStoreClient: scDynamicStoreClient,
            scNetworkInterfaceClient: scNetworkInterfaceClient,
            stateClient: stateClient,
            uiDeviceClient: uiDeviceClient,
            urlResourceValuesClient: urlResourceValuesClient
        )
    }
}
