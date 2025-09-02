import Foundation

struct URLClient: DependencyClient {
    var resourceValues: @Sendable (URL, Set<URLResourceKey>) throws -> URLResourceValues

    static let liveValue = Self(
        resourceValues: { try $0.resourceValues(forKeys: $1) }
    )

    static let testValue = Self(
        resourceValues: { _, _ in throw URLError(.resourceUnavailable) }
    )
}
