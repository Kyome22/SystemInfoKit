import Darwin
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

    private var vmStatistics64: vm_statistics64 {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var statistics = vm_statistics64()
        _ = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
                hostClient.statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
            }
        }
        return statistics
    }

    private var pageSize: vm_size_t {
        var size = vm_size_t()
        _ = withUnsafeMutablePointer(to: &size) { pointer in
            hostClient.pageSize(mach_host_self(), pointer)
        }
        return size
    }

    private var basicInfo: host_basic_info {
        var size = mach_msg_type_number_t(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        var basicInfo = host_basic_info()
        _ = withUnsafeMutablePointer(to: &basicInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
                hostClient.info(mach_host_self(), HOST_BASIC_INFO, pointer, &size)
            }
        }
        return basicInfo
    }

    func update() async {
        var result = MemoryInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.memoryInfo = result }
        }

        let statistics = vmStatistics64

        let active      = Double(statistics.active_count)
        let inactive    = Double(statistics.inactive_count)
        let speculative = Double(statistics.speculative_count)
        let wired       = Double(statistics.wire_count)
        let compressed  = Double(statistics.compressor_page_count)
        let purgeable   = Double(statistics.purgeable_count)
        let external    = Double(statistics.external_page_count)

        let cached = purgeable + external
        let app = active + inactive + speculative - cached
        let pressure = wired + compressed
        let using = app + pressure

        let size = Double(pageSize)
        let maxMemory = Double(basicInfo.max_mem)

        result.percentage = .init(rawValue: min((using * size) / maxMemory, 0.999), language: language)
        result.pressure = .init(rawValue: (pressure * size) / maxMemory, language: language)
        result.app = .init(byteCount: app * size, language: language)
        result.wired = .init(byteCount: wired * size, language: language)
        result.compressed = .init(byteCount: compressed * size, language: language)
    }

    func reset() {
        stateClient.withLock { $0.bundle.memoryInfo = nil }
    }
}
