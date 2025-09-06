import Foundation

struct URLResourceValuesClient: DependencyClient {
    var volumeTotalCapacity: @Sendable (URLResourceValues) -> Int?
    var volumeAvailableCapacityForImportantUsage: @Sendable (URLResourceValues) -> Int64?

    static let liveValue = Self(
        volumeTotalCapacity: { $0.volumeTotalCapacity },
        volumeAvailableCapacityForImportantUsage: { $0.volumeAvailableCapacityForImportantUsage }
    )

    static let testValue = Self(
        volumeTotalCapacity: { _ in nil },
        volumeAvailableCapacityForImportantUsage: { _ in nil }
    )
}
