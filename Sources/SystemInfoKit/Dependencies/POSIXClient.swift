import Darwin

struct POSIXClient: DependencyClient {
    var getNameInfo: @Sendable (UnsafePointer<sockaddr>?, socklen_t, UnsafeMutablePointer<CChar>?, socklen_t, UnsafeMutablePointer<CChar>?, socklen_t, Int32) -> Int32
    var getIfaddrs: @Sendable (UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>?) -> Int32
    var freeIfaddrs: @Sendable (UnsafeMutablePointer<ifaddrs>?) -> Void

    static let liveValue = Self(
        getNameInfo: { getnameinfo($0, $1, $2, $3, $4, $5, $6) },
        getIfaddrs: { getifaddrs($0) },
        freeIfaddrs: { freeifaddrs($0) }
    )

    static let testValue = Self(
        getNameInfo: { _, _, _, _, _, _, _ in EAI_FAIL },
        getIfaddrs: { _ in -1 },
        freeIfaddrs: { _ in }
    )
}
