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

        result.value = min(99.9, (100.0 * Double(used) / Double(total)).round2dp)
        result.totalValue = ByteData(byteCount: total)
        result.availableValue = ByteData(byteCount: available)
        result.usedValue = ByteData(byteCount: used)
    }

    mutating func reset() {
        current = StorageInfo()
    }
}
