@preconcurrency import Darwin

struct MemoryRepository: SystemRepository {
    private var stateClient: StateClient

    init(_ stateClient: StateClient) {
        self.stateClient = stateClient
    }

    private var maxMemory: Int64 {
        var size: mach_msg_type_number_t = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int()) { (pointer) -> kern_return_t in
            host_info(mach_host_self(), HOST_BASIC_INFO, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return Int64(data.max_mem)
    }

    private var vmStatistics64: vm_statistics64 {
        var size: mach_msg_type_number_t = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { (pointer) -> kern_return_t in
            host_statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }

    func update() {
        var result = MemoryInfo()
        defer {
            stateClient.withLock { [result] in $0.bundle.memoryInfo = result }
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

        result.percentage = .init(rawValue: min(Double(using) / Double(maxMem), 0.999))
        result.pressure = .init(rawValue: (Double(wired) + Double(compressed)) / Double(maxMem))
        result.app = .init(byteCount: using - wired - compressed)
        result.wired = .init(byteCount: wired)
        result.compressed = .init(byteCount: compressed)
    }

    func reset() {
        stateClient.withLock { $0.bundle.memoryInfo = .init() }
    }
}
