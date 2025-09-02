import Foundation

struct Dependencies: Sendable {
    var hostClient: HostClient
    var ioKitClient: IOKitClient
    var posixClient: POSIXClient
    var scDynamicStoreClient: SCDynamicStoreClient
    var scNetworkInterfaceClient: SCNetworkInterfaceClient
    var stateClient: StateClient
    var urlClient: URLClient

    init(
        hostClient: HostClient = .liveValue,
        ioKitClient: IOKitClient = .liveValue,
        posixClient: POSIXClient = .liveValue,
        scDynamicStoreClient: SCDynamicStoreClient = .liveValue,
        scNetworkInterfaceClient: SCNetworkInterfaceClient = .liveValue,
        stateClient: StateClient = .liveValue,
        urlClient: URLClient = .liveValue
    ) {
        self.hostClient = hostClient
        self.ioKitClient = ioKitClient
        self.posixClient = posixClient
        self.scDynamicStoreClient = scDynamicStoreClient
        self.scNetworkInterfaceClient = scNetworkInterfaceClient
        self.stateClient = stateClient
        self.urlClient = urlClient
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
        urlClient: URLClient = .testValue,
    ) -> Dependencies {
        Dependencies(
            hostClient: hostClient,
            ioKitClient: ioKitClient,
            posixClient: posixClient,
            scDynamicStoreClient: scDynamicStoreClient,
            scNetworkInterfaceClient: scNetworkInterfaceClient,
            stateClient: stateClient,
            urlClient: urlClient
        )
    }
}
