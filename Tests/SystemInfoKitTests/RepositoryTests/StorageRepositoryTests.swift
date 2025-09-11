import Foundation
import os
import Testing

@testable import SystemInfoKit

struct StorageRepositoryTests {
    @Test
    func update() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = StorageRepository(
            .testDependencies(
                stateClient: .testDependency(state),
                urlResourceValuesClient: testDependency(of: URLResourceValuesClient.self) {
                    $0.volumeTotalCapacity = { _ in 88888888 }
                    $0.volumeAvailableCapacityForImportantUsage = { _ in 44444444 }
                }
            ),
            language: .english
        )
        await sut.update()
        let actual = try #require({ state.withLock(\.bundle.storageInfo) }())
        let expect = [
            "Storage: 50.0% used",
            "44.4 MB / 88.9 MB",
        ].joined(separator: "\n\t")
        #expect(actual.description == expect)
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.storageInfo = .init(
                percentage: .init(rawValue: 0.4),
                total: .init(byteCount: 1.0),
                available: .init(byteCount: 0.6),
                used: .init(byteCount: 0.4),
                language: .english
            )
        }
        let sut = StorageRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        let expect = [
            "Storage:  0.0% used",
            "--- / ---",
        ].joined(separator: "\n\t")
        #expect(state.withLock(\.bundle.storageInfo)?.description == expect)
    }
}
