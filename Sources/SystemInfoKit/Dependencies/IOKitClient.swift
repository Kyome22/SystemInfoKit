import IOKit

struct IOKitClient: DependencyClient {
    var getMatchingService: @Sendable (mach_port_t, CFDictionary) -> io_service_t
    var close: @Sendable (io_service_t) -> kern_return_t
    var release: @Sendable (io_object_t) -> kern_return_t
    var registryEntryCreateCFProperties: @Sendable (io_registry_entry_t, UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>?, CFAllocator?, IOOptionBits) -> kern_return_t

    static let liveValue = Self(
        getMatchingService: { IOServiceGetMatchingService($0, $1) },
        close: { IOServiceClose($0) },
        release: { IOObjectRelease($0) },
        registryEntryCreateCFProperties: { IORegistryEntryCreateCFProperties($0, $1, $2, $3) }
    )

    static let testValue = Self(
        getMatchingService: { _, _ in IO_OBJECT_NULL },
        close: { _ in kIOReturnError },
        release: { _ in kIOReturnError },
        registryEntryCreateCFProperties: { _, _, _, _ in kIOReturnError }
    )
}
