import Foundation

struct StorageRepository: SystemRepository {
    private var stateClient: StateClient

    init(_ stateClient: StateClient) {
        self.stateClient = stateClient
    }

    func update() {
        var result = StorageInfo()
        defer {
            stateClient.withLock { [result] in $0.bundle.storageInfo = result }
        }

        let url = NSURL(fileURLWithPath: "/")
        let keys: [URLResourceKey] = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let dict = try? url.resourceValues(forKeys: keys) else { return }
        let total = (dict[URLResourceKey.volumeTotalCapacityKey] as! NSNumber).int64Value
        let available = (dict[URLResourceKey.volumeAvailableCapacityForImportantUsageKey] as! NSNumber).int64Value
        let used: Int64 = total - available

        result.percentage = .init(rawValue: min(Double(used) / Double(total), 0.999))
        result.total = .init(byteCount: total)
        result.available = .init(byteCount: available)
        result.used = .init(byteCount: used)
    }

    func reset() {
        stateClient.withLock { $0.bundle.storageInfo = .init() }
    }
}
