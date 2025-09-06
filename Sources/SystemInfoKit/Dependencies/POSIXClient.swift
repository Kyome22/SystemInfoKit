import Darwin

struct POSIXClient: DependencyClient {
    var getIfaddrs: @Sendable (UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>?) -> Int32
    var getNameInfo: @Sendable (UnsafePointer<sockaddr>?, socklen_t, UnsafeMutablePointer<CChar>?, socklen_t, UnsafeMutablePointer<CChar>?, socklen_t, Int32) -> Int32
    var freeIfaddrs: @Sendable (UnsafeMutablePointer<ifaddrs>?) -> Void

    static let liveValue = Self(
        getIfaddrs: { getifaddrs($0) },
        getNameInfo: { getnameinfo($0, $1, $2, $3, $4, $5, $6) },
        freeIfaddrs: { freeifaddrs($0) }
    )

    static let testValue = Self(
        getIfaddrs: { _ in -1 },
        getNameInfo: { _, _, _, _, _, _, _ in EAI_FAIL },
        freeIfaddrs: { _ in }
    )
}
