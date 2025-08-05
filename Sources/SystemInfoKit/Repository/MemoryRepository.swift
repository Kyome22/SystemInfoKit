@preconcurrency import Darwin

struct MemoryRepository: Sendable {
    var current = MemoryInfo()
    private let hostVmInfo64Count: mach_msg_type_number_t!
    private let hostBasicInfoCount: mach_msg_type_number_t!

    init() {
        hostVmInfo64Count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        hostBasicInfoCount = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
    }

    private var maxMemory: Int64 {
        var size: mach_msg_type_number_t = hostBasicInfoCount
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int()) { (pointer) -> kern_return_t in
            host_info(mach_host_self(), HOST_BASIC_INFO, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return Int64(data.max_mem)
    }

    private var vmStatistics64: vm_statistics64 {
        var size: mach_msg_type_number_t = hostVmInfo64Count
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { (pointer) -> kern_return_t in
            host_statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }

    mutating func update() {
        var result = MemoryInfo()

        defer {
            current = result
        }

        let maxMem = maxMemory
        let load = vmStatistics64

        let page        = Int64(vm_kernel_page_size)
        let active      = Int64(load.active_count) * page
        let speculative = Int64(load.speculative_count) * page
        let inactive    = Int64(load.inactive_count) * page
        let wired       = Int64(load.wire_count) * page
        let compressed  = Int64(load.compressor_page_count) * page
        let purgeable   = Int64(load.purgeable_count) * page
        let external    = Int64(load.external_page_count) * page
        let using       = active + inactive + speculative + wired + compressed - purgeable - external

        result.value = min(99.9, (100.0 * Double(using) / Double(maxMem)).round2dp)
        result.pressureValue = (100.0 * (Double(wired) + Double(compressed)) / Double(maxMem)).round2dp
        result.appValue = ByteData(byteCount: using - wired - compressed)
        result.wiredValue = ByteData(byteCount: wired)
        result.compressedValue = ByteData(byteCount: compressed)
    }

    mutating func reset() {
        current = MemoryInfo()
    }
}
