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

    private func storageCapacitySnapshot(url: URL, currentAvailable: Int64) -> StorageCapacitySnapshot? {
        if let snapshot = stateClient.withLock(\.storageCapacitySnapshot), !snapshot.isExpired {
            return snapshot
        }
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let availableForImportantUsage = urlResourceValuesClient.volumeAvailableCapacityForImportantUsage(values) else {
            return nil
        }
        let snapshot = StorageCapacitySnapshot(
            availableForImportantUsage: availableForImportantUsage,
            available: currentAvailable,
            capturedAt: .now
        )
        stateClient.withLock { $0.storageCapacitySnapshot = snapshot }
        return snapshot
    }

    func update() async {
        var result = StorageInfo(language: language)
        defer {
            stateClient.withLock { [result] in $0.bundle.storageInfo = result }
        }

        let url = URL(filePath: "/")
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]
        guard let values = try? url.resourceValues(forKeys: keys),
              let total = urlResourceValuesClient.volumeTotalCapacity(values).map(Double.init),
              let currentAvailable = urlResourceValuesClient.volumeAvailableCapacity(values).map(Int64.init),
              let snapshot = storageCapacitySnapshot(url: url, currentAvailable: currentAvailable) else {
            return
        }
        let drift = currentAvailable - snapshot.available
        let available = min(max(Double(snapshot.availableForImportantUsage + drift), .zero), total)
        let used = total - available
        result.percentage = .init(rawValue: min(used / total, 0.999), language: language)
        result.total = .init(byteCount: total, language: language)
        result.available = .init(byteCount: available, language: language)
        result.used = .init(byteCount: used, language: language)
    }

    func setInitial() {
        stateClient.withLock {
            $0.bundle.storageInfo = .init(language: language)
        }
    }

    func reset() {
        stateClient.withLock {
            $0.bundle.storageInfo = nil
            $0.storageCapacitySnapshot = nil
        }
    }
}
