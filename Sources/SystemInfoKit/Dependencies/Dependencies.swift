import Foundation

struct Dependencies: Sendable {
    var hostClient: HostClient
    var ioKitClient: IOKitClient
    var posixClient: POSIXClient
    var scDynamicStoreClient: SCDynamicStoreClient
    var scNetworkInterfaceClient: SCNetworkInterfaceClient
    var stateClient: StateClient
    var urlResourceValuesClient: URLResourceValuesClient

    init(
        hostClient: HostClient = .liveValue,
        ioKitClient: IOKitClient = .liveValue,
        posixClient: POSIXClient = .liveValue,
        scDynamicStoreClient: SCDynamicStoreClient = .liveValue,
        scNetworkInterfaceClient: SCNetworkInterfaceClient = .liveValue,
        stateClient: StateClient = .liveValue,
        urlResourceValuesClient: URLResourceValuesClient = .liveValue
    ) {
        self.hostClient = hostClient
        self.ioKitClient = ioKitClient
        self.posixClient = posixClient
        self.scDynamicStoreClient = scDynamicStoreClient
        self.scNetworkInterfaceClient = scNetworkInterfaceClient
        self.stateClient = stateClient
        self.urlResourceValuesClient = urlResourceValuesClient
    }
}

extension Dependencies {
    static func testDependencies(
        hostClient: HostClient = .testValue,
        ioKitClient: IOKitClient = .testValue,
        posixClient: POSIXClient = .testValue,
        scDynamicStoreClient: SCDynamicStoreClient = .testValue,
        scNetworkInterfaceClient: SCNetworkInterfaceClient = .testValue,
        stateClient: StateClient = .testValue,
        urlResourceValuesClient: URLResourceValuesClient = .testValue,
    ) -> Dependencies {
        Dependencies(
            hostClient: hostClient,
            ioKitClient: ioKitClient,
            posixClient: posixClient,
            scDynamicStoreClient: scDynamicStoreClient,
            scNetworkInterfaceClient: scNetworkInterfaceClient,
            stateClient: stateClient,
            urlResourceValuesClient: urlResourceValuesClient
        )
    }
}
