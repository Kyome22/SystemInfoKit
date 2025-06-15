import Foundation

struct StorageRepository: Sendable {
    var current = StorageInfo()

    private func convertByteData(_ byteCount: Int64) -> ByteData {
        let style = ByteCountFormatStyle(
            style: .decimal,
            allowedUnits: [.kb, .mb, .gb, .tb, .pb, .eb],
            locale: Locale(identifier: "en_US")
        )
        let array = style.format(byteCount).components(separatedBy: .whitespaces)
        return ByteData(value: Double(array[0]) ?? 0.0, unit: array[1])
    }

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
        result.totalValue = convertByteData(total)
        result.availableValue = convertByteData(available)
        result.usedValue = convertByteData(used)
    }

    mutating func reset() {
        current = StorageInfo()
    }
}
