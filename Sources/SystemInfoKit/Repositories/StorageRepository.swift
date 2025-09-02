import Foundation

struct StorageRepository: SystemRepository {
    private var stateClient: StateClient
    private var urlClient: URLClient

    init(_ dependencies: Dependencies) {
        stateClient = dependencies.stateClient
        urlClient = dependencies.urlClient
    }

    func update() {
        var result = StorageInfo()
        defer {
            stateClient.withLock { [result] in $0.bundle.storageInfo = result }
        }

        let url = URL(filePath: "/")
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? urlClient.resourceValues(url, keys),
              let total = values.volumeTotalCapacity.map(Double.init),
              let available = values.volumeAvailableCapacityForImportantUsage.map(Double.init) else {
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
