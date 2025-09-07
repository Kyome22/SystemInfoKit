@preconcurrency import Darwin
import Foundation

struct MemoryRepository: SystemRepository {
    private var hostClient: HostClient
    private var stateClient: StateClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        hostClient = dependencies.hostClient
        stateClient = dependencies.stateClient
        self.language = language
    }

    private var maxMemory: Double {
        var size: mach_msg_type_number_t = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { (pointer) -> kern_return_t in
            hostClient.info(mach_host_self(), HOST_BASIC_INFO, pointer, &size)
        }
        let data = if result == KERN_SUCCESS {
            hostInfo.move()
        } else {
            host_basic_info()
        }
        hostInfo.deallocate()
        return Double(data.max_mem)
    }

    private var vmStatistics64: vm_statistics64 {
        var size: mach_msg_type_number_t = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { (pointer) -> kern_return_t in
            hostClient.statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
        }
        let data = if result == KERN_SUCCESS {
            hostInfo.move()
        } else {
            vm_statistics64()
        }
        hostInfo.deallocate()
        return data
    }

    func update() {
        var result = MemoryInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.memoryInfo = result }
        }

        let load = vmStatistics64
        let maxMem = maxMemory

        let page        = Double(vm_kernel_page_size)
        let active      = Double(load.active_count)
        let inactive    = Double(load.inactive_count)
        let speculative = Double(load.speculative_count)
        let purgeable   = Double(load.purgeable_count)
        let external    = Double(load.external_page_count)
        let app         = (active + inactive + speculative - purgeable - external) * page
        let wired       = Double(load.wire_count) * page
        let compressed  = Double(load.compressor_page_count) * page

        result.percentage = .init(rawValue: min((app + wired + compressed) / maxMem, 0.999), language: language)
        result.pressure = .init(rawValue: (wired + compressed) / maxMem, language: language)
        result.app = .init(byteCount: app, language: language)
        result.wired = .init(byteCount: wired, language: language)
        result.compressed = .init(byteCount: compressed, language: language)
    }

    func reset() {
        stateClient.withLock { $0.bundle.memoryInfo = .init(language: language) }
    }
}
