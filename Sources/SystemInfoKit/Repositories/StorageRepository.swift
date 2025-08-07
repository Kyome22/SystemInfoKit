import Foundation

struct StorageRepository: Sendable {
    var current = StorageInfo()

    mutating func update() {
        var result = StorageInfo()

        defer {
            current = result
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

    mutating func reset() {
        current = StorageInfo()
    }
}
