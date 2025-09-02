import Darwin

struct CPURepository: SystemRepository {
    private var systemInfoStateClient: SystemInfoStateClient

    init(_ systemInfoStateClient: SystemInfoStateClient) {
        self.systemInfoStateClient = systemInfoStateClient
    }

    private func hostCPULoadInfo() -> host_cpu_load_info {
        var size: mach_msg_type_number_t = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &size)
        }
        let data = if result == KERN_SUCCESS {
            hostInfo.move()
        } else {
            host_cpu_load_info()
        }
        hostInfo.deallocate()
        return data
    }

    func update() {
        var result = CPUInfo()
        defer {
            systemInfoStateClient.withLock { [result] in $0.bundle.cpuInfo = result }
        }

        let previousLoadInfo = systemInfoStateClient.withLock(\.previousLoadInfo)
        let loadInfo = hostCPULoadInfo()
        let userDiff = Double(loadInfo.cpu_ticks.0 - previousLoadInfo.cpu_ticks.0)
        let systemDiff  = Double(loadInfo.cpu_ticks.1 - previousLoadInfo.cpu_ticks.1)
        let idleDiff = Double(loadInfo.cpu_ticks.2 - previousLoadInfo.cpu_ticks.2)
        let niceDiff = Double(loadInfo.cpu_ticks.3 - previousLoadInfo.cpu_ticks.3)
        systemInfoStateClient.withLock { $0.previousLoadInfo = loadInfo }

        let totalTicks = systemDiff + userDiff + idleDiff + niceDiff
        let system  = systemDiff / totalTicks
        let user = userDiff / totalTicks
        let idle = idleDiff / totalTicks

        result.percentage = .init(rawValue: min(system + user, 0.999))
        result.system = .init(rawValue: system)
        result.user = .init(rawValue: user)
        result.idle = .init(rawValue: idle)
    }

    func reset() {
        systemInfoStateClient.withLock {
            $0.bundle.cpuInfo = .init()
            $0.previousLoadInfo = .init()
        }
    }
}
