import Foundation

struct URLResourceValuesClient: DependencyClient {
    var volumeTotalCapacity: @Sendable (URLResourceValues) -> Int?
    var volumeAvailableCapacity: @Sendable (URLResourceValues) -> Int?
    var volumeAvailableCapacityForImportantUsage: @Sendable (URLResourceValues) -> Int64?

    static let liveValue = Self(
        volumeTotalCapacity: { $0.volumeTotalCapacity },
        volumeAvailableCapacity: { $0.volumeAvailableCapacity },
        volumeAvailableCapacityForImportantUsage: { $0.volumeAvailableCapacityForImportantUsage }
    )

    static let testValue = Self(
        volumeTotalCapacity: { _ in nil },
        volumeAvailableCapacity: { _ in nil },
        volumeAvailableCapacityForImportantUsage: { _ in nil }
    )
}
