import Darwin
import Foundation

struct CPURepository: SystemRepository {
    private var hostClient: HostClient
    private var stateClient: StateClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        hostClient = dependencies.hostClient
        stateClient = dependencies.stateClient
        self.language = language
    }

    private func hostCPULoadInfo() -> host_cpu_load_info {
        var size: mach_msg_type_number_t = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
            hostClient.statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &size)
        }
        let data = if result == KERN_SUCCESS {
            hostInfo.move()
        } else {
            host_cpu_load_info()
        }
        hostInfo.deallocate()
        return data
    }

    func update() async {
        var result = CPUInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.cpuInfo = result }
        }

        let previousLoadInfo = stateClient.withLock(\.previousLoadInfo)
        let loadInfo = hostCPULoadInfo()
        let userDiff = Double(loadInfo.cpu_ticks.0 - previousLoadInfo.cpu_ticks.0)
        let systemDiff  = Double(loadInfo.cpu_ticks.1 - previousLoadInfo.cpu_ticks.1)
        let idleDiff = Double(loadInfo.cpu_ticks.2 - previousLoadInfo.cpu_ticks.2)
        let niceDiff = Double(loadInfo.cpu_ticks.3 - previousLoadInfo.cpu_ticks.3)
        stateClient.withLock { $0.previousLoadInfo = loadInfo }

        let totalTicks = systemDiff + userDiff + idleDiff + niceDiff
        let system  = systemDiff / totalTicks
        let user = userDiff / totalTicks
        let idle = idleDiff / totalTicks

        result.percentage = .init(rawValue: min(system + user, 0.999), language: language)
        result.system = .init(rawValue: system, language: language)
        result.user = .init(rawValue: user, language: language)
        result.idle = .init(rawValue: idle, language: language)
    }

    func reset() {
        stateClient.withLock {
            $0.bundle.cpuInfo = .init(language: language)
            $0.previousLoadInfo = .init()
        }
    }
}
