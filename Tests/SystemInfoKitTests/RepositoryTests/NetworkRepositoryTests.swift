import Foundation
import Network
import os
import Testing

@testable import SystemInfoKit

struct NetworkRepositoryTests {
    @Test
    func update() async throws {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.interval = 1.0
            $0.previousDataTraffic = .init(upload: 1000, download: 1000000)
        }
        let sut = NetworkRepository(
            .testDependencies(
                nwPathMonitorClient: testDependency(of: NWPathMonitorClient.self) {
                    $0.currentStatus = { .satisfied }
                    $0.currentAvailableInterfaceTypes = {
                        [NWInterface.InterfaceType.wiredEthernet]
                    }
                    $0.currentGateways = {
                        [NWEndpoint.hostPort(host: .ipv4(.any), port: .any)]
                    }
                },
                posixClient: testDependency(of: POSIXClient.self) {
                    $0.getIfaddrs = { pointer in
                        pointer?.pointee =  NRMock.inetIfaddrsPointer(next: NRMock.linkIfaddrsPointer())
                        return .zero
                    }
                    $0.getNameInfo = { getnameinfo($0, $1, $2, $3, $4, $5, $6) }
                },
                stateClient: .testDependency(state)
            ),
            language: .english
        )
        await sut.update()
        let actual = try #require({ state.withLock(\.bundle.networkInfo) }())
        let expect = [
            "Network: Ethernet",
            "Local IP: 0.0.0.0",
            "Upload:  7.9 kB/s",
            "Download:  7.9 MB/s",
        ].joined(separator: "\n\t")
        #expect(actual.description == expect)
    }

    @Test
    func reset() {
        let state = OSAllocatedUnfairLock<State>(initialState: .init())
        state.withLock {
            $0.bundle.networkInfo = .zero
            $0.previousDataTraffic = .init(upload: 8888, download: 8888888)
        }
        let sut = NetworkRepository(.testDependencies(stateClient: .testDependency(state)), language: .english)
        sut.reset()
        #expect(state.withLock(\.bundle.networkInfo) == nil)
        #expect(state.withLock(\.previousDataTraffic) == .zero)
    }
}

private enum NRMock {
    static func inetIfaddrsPointer(next: UnsafeMutablePointer<ifaddrs>? = nil) -> UnsafeMutablePointer<ifaddrs> {
        var addr = sockaddr()
        addr.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        addr.sa_family = sa_family_t(AF_INET)

        let addrPointer = UnsafeMutablePointer<sockaddr>.allocate(capacity: 1)
        addrPointer.initialize(to: addr)

        let value = ifaddrs(
            ifa_next: next,
            ifa_name: strdup("dummy"),
            ifa_flags: UInt32(IFF_UP | IFF_RUNNING),
            ifa_addr: addrPointer,
            ifa_netmask: nil,
            ifa_dstaddr: nil,
            ifa_data: nil
        )

        let ifaddrsPointer = UnsafeMutablePointer<ifaddrs>.allocate(capacity: 1)
        ifaddrsPointer.initialize(to: value)

        return ifaddrsPointer
    }

    static func linkIfaddrsPointer(next: UnsafeMutablePointer<ifaddrs>? = nil) -> UnsafeMutablePointer<ifaddrs> {
        var addr = sockaddr()
        addr.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        addr.sa_family = sa_family_t(AF_LINK)

        let addrPointer = UnsafeMutablePointer<sockaddr>.allocate(capacity: 1)
        addrPointer.initialize(to: addr)

        var data = if_data()
        data.ifi_obytes = 8888
        data.ifi_ibytes = 8888888

        let dataPointer = UnsafeMutablePointer<if_data>.allocate(capacity: 1)
        dataPointer.initialize(to: data)

        let value = ifaddrs(
            ifa_next: next,
            ifa_name: strdup("dummy"),
            ifa_flags: UInt32(IFF_UP | IFF_RUNNING),
            ifa_addr: addrPointer,
            ifa_netmask: nil,
            ifa_dstaddr: nil,
            ifa_data: dataPointer
        )

        let ifaddrsPointer = UnsafeMutablePointer<ifaddrs>.allocate(capacity: 1)
        ifaddrsPointer.initialize(to: value)

        return ifaddrsPointer
    }
}
