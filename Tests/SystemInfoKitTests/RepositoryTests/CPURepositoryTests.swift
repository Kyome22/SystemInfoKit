import os
import Testing

@testable import SystemInfoKit

struct CPURepositoryTests {
    @Test
    func update() throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.previousLoadInfo.cpu_ticks = (62511937, 33202830, 859088048, 0)
        }
        let sut = CPURepository(
            .testDependencies(
                hostClient: testDependency(of: HostClient.self) {
                    $0.statistics64 = { _, _, pointer, _ in
                        pointer?[0] = 62512420
                        pointer?[1] = 33203135
                        pointer?[2] = 859090523
                        pointer?[3] = 0
                        return KERN_SUCCESS
                    }
                },
                stateClient: .testDependency(state)
            ),
            language: .english
        )
        sut.update()
        let actual = try #require({ state.withLock(\.bundle.cpuInfo) }())
        let expect = [
            "CPU: 24.1%",
            "System:  9.3%",
            "User: 14.8%",
            "Idle: 75.9%",
        ].joined(separator: "\n\t")
        #expect(actual.description == expect)
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.cpuInfo = .init(
                percentage: .init(rawValue: 0.241),
                system: .init(rawValue: 0.93),
                user: .init(rawValue: 0.148),
                idle: .init(rawValue: 0.759),
                language: .english
            )
            $0.previousLoadInfo.cpu_ticks = (62511937, 33202830, 859088048, 0)
        }
        let sut = CPURepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        let expect = [
            "CPU:  0.0%",
            "System:  0.0%",
            "User:  0.0%",
            "Idle:  0.0%",
        ].joined(separator: "\n\t")
        #expect(state.withLock(\.bundle.cpuInfo)?.description == expect)
        #expect(state.withLock(\.previousLoadInfo.cpu_ticks) == (0, 0, 0, 0))
    }
}
