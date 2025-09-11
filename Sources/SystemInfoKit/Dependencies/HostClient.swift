import Darwin

struct HostClient: DependencyClient {
    var statistics64: @Sendable (host_t, host_flavor_t, host_info_t?, UnsafeMutablePointer<mach_msg_type_number_t>?) -> kern_return_t
    var pageSize: @Sendable (host_t, UnsafeMutablePointer<vm_size_t>?) -> kern_return_t
    var info: @Sendable (host_t, host_flavor_t, host_info_t?, UnsafeMutablePointer<mach_msg_type_number_t>?) -> kern_return_t

    static let liveValue = Self(
        statistics64: { host_statistics64($0, $1, $2, $3) },
        pageSize: { host_page_size($0, $1) },
        info: { host_info($0, $1, $2, $3) }
    )

    static let testValue = Self(
        statistics64: { _, _, _, _ in KERN_FAILURE },
        pageSize: { _, _ in KERN_FAILURE },
        info: { _, _, _, _ in KERN_FAILURE }
    )
}
