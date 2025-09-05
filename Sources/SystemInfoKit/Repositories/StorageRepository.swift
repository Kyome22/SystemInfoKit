import Foundation

struct StorageRepository: SystemRepository {
    private var stateClient: StateClient
    private var urlResourceValuesClient: URLResourceValuesClient

    init(_ dependencies: Dependencies) {
        stateClient = dependencies.stateClient
        urlResourceValuesClient = dependencies.urlResourceValuesClient
    }

    func update() {
        var result = StorageInfo()
        defer {
            stateClient.withLock { [result] in $0.bundle.storageInfo = result }
        }

        let url = URL(filePath: "/")
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? url.resourceValues(forKeys: keys),
              let total = urlResourceValuesClient.volumeTotalCapacity(values).map(Double.init),
              let available = urlResourceValuesClient.volumeAvailableCapacityForImportantUsage(values).map(Double.init) else {
            return
        }
        let used = total - available
        result.percentage = .init(rawValue: min(used / total, 0.999))
        result.total = .init(byteCount: total)
        result.available = .init(byteCount: available)
        result.used = .init(byteCount: used)
    }

    func reset() {
        stateClient.withLock { $0.bundle.storageInfo = .init() }
    }
}
