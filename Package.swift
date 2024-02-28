// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "ActivityKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ActivityKit",
            targets: ["ActivityKit"]
        )
    ],
    targets: [
        .target(
            name: "ActivityKit",
        ),
        .testTarget(
            name: "ActivityKitTests",
            dependencies: ["ActivityKit"]
        )
    ]
)
