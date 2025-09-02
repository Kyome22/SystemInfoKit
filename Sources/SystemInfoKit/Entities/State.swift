import Darwin

struct State: Sendable {
    var activationState: [SystemInfoType: Bool] = Dictionary(
        uniqueKeysWithValues: SystemInfoType.allCases.map({ ($0, true) })
    )
    var bundle = SystemInfoBundle()
    var interval: Double = 1.0
    var previousLoadInfo = host_cpu_load_info()
    var latestIPAddress = IPAddress.uninitialized
    var previousDataTraffic = DataTraffic.zero
}
