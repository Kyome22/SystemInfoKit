// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "SystemInfoKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12)
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
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SystemInfoKitTests",
            dependencies: ["SystemInfoKit"]
        )
    ]
)
