struct StorageCapacitySnapshot: Sendable {
    static let lifetime = Duration.seconds(60)

    var availableForImportantUsage: Int64
    var available: Int64
    var capturedAt: ContinuousClock.Instant

    var isExpired: Bool {
        capturedAt.duration(to: .now) >= Self.lifetime
    }
}
