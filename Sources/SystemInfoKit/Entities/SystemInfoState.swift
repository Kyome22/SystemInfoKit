import Darwin

struct SystemInfoState: Sendable {
    var activationState: [SystemInfoType: Bool] = Dictionary(
        uniqueKeysWithValues: SystemInfoType.allCases.map({ ($0, true) })
    )
    var bundle = SystemInfoBundle()
    var interval: Double = 1.0
    var previousLoadInfo = host_cpu_load_info()
    var previousNetworkLoad = NetworkLoad.zero
    var latestIP = "-"
}
