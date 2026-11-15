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
        #expect(state.withLock(\.storageCapacitySnapshot?.availableForImportantUsage) == 44444444)
    }

    @Test
    func update_shifts_fresh_snapshot_by_available_capacity_drift() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.storageCapacitySnapshot = .init(
                availableForImportantUsage: 66666666,
                available: 55555555,
                capturedAt: .now
            )
        }
        let importantUsageReadCount = OSAllocatedUnfairLock(initialState: 0)
        let sut = StorageRepository(
            .testDependencies(
                stateClient: .testDependency(state),
                urlResourceValuesClient: testDependency(of: URLResourceValuesClient.self) {
                    $0.volumeTotalCapacity = { _ in 88888888 }
                    $0.volumeAvailableCapacity = { _ in 33333333 }
                    $0.volumeAvailableCapacityForImportantUsage = { _ in
                        importantUsageReadCount.withLock { $0 += 1 }
                        return 11111111
                    }
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
        #expect(importantUsageReadCount.withLock(\.self) == 0)
    }

    @Test
    func update_refreshes_expired_snapshot() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.storageCapacitySnapshot = .init(
                availableForImportantUsage: 11111111,
                available: 11111111,
                capturedAt: .now - StorageCapacitySnapshot.lifetime
            )
        }
        let sut = StorageRepository(
            .testDependencies(
                stateClient: .testDependency(state),
                urlResourceValuesClient: testDependency(of: URLResourceValuesClient.self) {
                    $0.volumeTotalCapacity = { _ in 88888888 }
                    $0.volumeAvailableCapacity = { _ in 33333333 }
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
        #expect(state.withLock(\.storageCapacitySnapshot?.availableForImportantUsage) == 44444444)
        #expect(state.withLock(\.storageCapacitySnapshot?.available) == 33333333)
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.storageInfo = .zero
            $0.storageCapacitySnapshot = .init(availableForImportantUsage: 1, available: 1, capturedAt: .now)
        }
        let sut = StorageRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        #expect(state.withLock(\.bundle.storageInfo) == nil)
        #expect(state.withLock(\.storageCapacitySnapshot) == nil)
    }
}
