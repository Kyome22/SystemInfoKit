import SystemConfiguration

#if os(macOS)
struct SCDynamicStoreClient: DependencyClient {
    var create: @Sendable (CFAllocator?, CFString, SCDynamicStoreCallBack?, UnsafeMutablePointer<SCDynamicStoreContext>?) -> SCDynamicStore?
    var keyCreateNetworkGlobalEntity: @Sendable (CFAllocator?, CFString, CFString) -> CFString
    var copyValue: @Sendable (SCDynamicStore?, CFString) -> CFPropertyList?

    static let liveValue = Self(
        create: { SCDynamicStoreCreate($0, $1, $2, $3) },
        keyCreateNetworkGlobalEntity: { SCDynamicStoreKeyCreateNetworkGlobalEntity($0, $1, $2) },
        copyValue: { SCDynamicStoreCopyValue($0, $1) }
    )

    static let testValue = Self(
        create: { _, _, _, _ in nil },
        keyCreateNetworkGlobalEntity: { _, _, _ in "" as CFString },
        copyValue: { _, _ in nil }
    )
}
#else
struct SCDynamicStoreClient: DependencyClient {
    static let liveValue = Self()
    static let testValue = Self()
}
#endif
