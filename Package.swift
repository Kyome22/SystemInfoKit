// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ActivityKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ActivityKit",
            targets: ["ActivityKit"]),
    ],
    targets: [
        .target(
            name: "ActivityKit",
            dependencies: []),
        .testTarget(
            name: "ActivityKitTests",
            dependencies: ["ActivityKit"]),
    ]
)
