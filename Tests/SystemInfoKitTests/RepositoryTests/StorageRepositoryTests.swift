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
                    $0.volumeAvailableCapacity = { _ in 44444444 }
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
    func update_reads_important_usage_once_per_refresh_window() async {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock { $0.interval = 30.0 }
        let importantUsageReadCount = OSAllocatedUnfairLock(initialState: 0)
        let sut = StorageRepository(
            .testDependencies(
                stateClient: .testDependency(state),
                urlResourceValuesClient: testDependency(of: URLResourceValuesClient.self) {
                    $0.volumeTotalCapacity = { _ in 88888888 }
                    $0.volumeAvailableCapacity = { _ in 44444444 }
                    $0.volumeAvailableCapacityForImportantUsage = { _ in
                        importantUsageReadCount.withLock { $0 += 1 }
                        return 44444444
                    }
                }
            ),
            language: .english
        )
        await sut.update()
        await sut.update()
        await sut.update()
        #expect(importantUsageReadCount.withLock(\.self) == 2)
    }

    @Test
    func update_shifts_cached_important_usage_by_available_capacity_drift() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock { $0.interval = 5.0 }
        let availableCapacities = OSAllocatedUnfairLock(initialState: [55555555, 33333333])
        let sut = StorageRepository(
            .testDependencies(
                stateClient: .testDependency(state),
                urlResourceValuesClient: testDependency(of: URLResourceValuesClient.self) {
                    $0.volumeTotalCapacity = { _ in 88888888 }
                    $0.volumeAvailableCapacity = { _ in availableCapacities.withLock { $0.removeFirst() } }
                    $0.volumeAvailableCapacityForImportantUsage = { _ in 66666666 }
                }
            ),
            language: .english
        )
        await sut.update()
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
            $0.bundle.storageInfo = .zero
            $0.storageCapacitySnapshot = .init(availableForImportantUsage: 1, available: 1, remainingUpdates: 1)
        }
        let sut = StorageRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        #expect(state.withLock(\.bundle.storageInfo) == nil)
        #expect(state.withLock(\.storageCapacitySnapshot) == nil)
    }
}
