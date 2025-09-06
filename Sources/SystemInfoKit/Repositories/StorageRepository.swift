import Foundation

struct StorageRepository: SystemRepository {
    private var stateClient: StateClient
    private var urlResourceValuesClient: URLResourceValuesClient
    var language: Language

    init(_ dependencies: Dependencies, language: Language) {
        stateClient = dependencies.stateClient
        urlResourceValuesClient = dependencies.urlResourceValuesClient
        self.language = language
    }

    func update() {
        var result = StorageInfo(language: language)
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
        result.percentage = .init(rawValue: min(used / total, 0.999), language: language)
        result.total = .init(byteCount: total, language: language)
        result.available = .init(byteCount: available, language: language)
        result.used = .init(byteCount: used, language: language)
    }

    func reset() {
        stateClient.withLock { $0.bundle.storageInfo = .init(language: language) }
    }
}
