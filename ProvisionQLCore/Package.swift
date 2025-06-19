// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProvisionQLCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "ProvisionQLCore",
            targets: ["ProvisionQLCore"]
        ),
    ],
    targets: [
        .target(
            name: "ProvisionQLCore",
            path: "Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ProvisionQLCoreTests",
            dependencies: ["ProvisionQLCore"],
            path: "Tests"
        ),
    ]
)
