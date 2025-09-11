import os
import Testing

@testable import SystemInfoKit

struct MemoryRepositoryTests {
    @Test
    func update() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let sut = MemoryRepository(
            .testDependencies(
                hostClient: testDependency(of: HostClient.self) {
                    $0.statistics64 = { _, _, pointer, _ in
                        pointer?[1] = 155022
                        pointer?[2] = 141526
                        pointer?[3] = 235904
                        pointer?[22] = 0
                        pointer?[23] = 12539
                        pointer?[32] = 452725
                        pointer?[34] = 138560
                        return KERN_SUCCESS
                    }
                    $0.info = { _, _, pointer, _ in
                        pointer?[10] = 0
                        pointer?[11] = 4
                        return KERN_SUCCESS
                    }
                    $0.pageSize = { _, pointer in
                        pointer?[0] = 16384
                        return KERN_SUCCESS
                    }
                },
                stateClient: .testDependency(state)
            ),
            language: .english
        )
        await sut.update()
        let actual = try #require({ state.withLock(\.bundle.memoryInfo) }())
        let expect = [
            "Memory: 81.9%",
            "Pressure: 65.7%",
            "App Memory:  2.8 GB",
            "Wired Memory:  3.9 GB",
            "Compressed:  7.4 GB",
        ].joined(separator: "\n\t")
        #expect(actual.description == expect)
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.memoryInfo = .init(
                percentage: .init(rawValue: 0.819),
                pressure: .init(rawValue: 0.657),
                app: .init(byteCount: 2800000000),
                wired: .init(byteCount: 3900000000),
                compressed: .init(byteCount: 7400000000),
                language: .english
            )
        }
        let sut = MemoryRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        let expect = [
            "Memory:  0.0%",
            "Pressure:  0.0%",
            "App Memory:  0.0 B",
            "Wired Memory:  0.0 B",
            "Compressed:  0.0 B",
        ].joined(separator: "\n\t")
        #expect(state.withLock(\.bundle.memoryInfo)?.description == expect)
    }
}
