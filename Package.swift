// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "SystemInfoKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SystemInfoKit",
            targets: ["SystemInfoKit"]
        )
    ],
    targets: [
        .target(
            name: "SystemInfoKit",
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SystemInfoKitTests",
            dependencies: ["SystemInfoKit"],
            swiftSettings: swiftSettings
        )
    ]
)
