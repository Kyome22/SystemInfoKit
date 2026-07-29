import os
import Testing

@testable import SystemInfoKit

struct CPURepositoryTests {
    @Test
    func update() async throws {
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
        await sut.update()
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
    func update_deallocates_every_host_port() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        let acquiredCount = OSAllocatedUnfairLock<Int>(initialState: 0)
        let deallocatedCount = OSAllocatedUnfairLock<Int>(initialState: 0)
        let sut = CPURepository(
            .testDependencies(
                hostClient: testDependency(of: HostClient.self) {
                    $0.hostSelf = {
                        acquiredCount.withLock { count in count += 1 }
                        return 1
                    }
                    $0.deallocatePort = { _ in
                        deallocatedCount.withLock { count in count += 1 }
                        return KERN_SUCCESS
                    }
                    $0.statistics64 = { _, _, _, _ in KERN_SUCCESS }
                },
                stateClient: .testDependency(state)
            ),
            language: .english
        )
        await sut.update()
        #expect(acquiredCount.withLock(\.self) == 1)
        #expect(deallocatedCount.withLock(\.self) == 1)
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.cpuInfo = .zero
            $0.previousLoadInfo.cpu_ticks = (62511937, 33202830, 859088048, 0)
        }
        let sut = CPURepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        #expect(state.withLock(\.bundle.cpuInfo) == nil)
        #expect(state.withLock(\.previousLoadInfo.cpu_ticks) == (0, 0, 0, 0))
    }
}
