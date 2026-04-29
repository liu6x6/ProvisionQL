// swift-tools-version: 6.0

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
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/tsolomko/SWCompression.git", from: "4.8.0"),
        .package(path: "/Users/spxt666/SwiftAXML"),
    ],
    targets: [
        .target(
            name: "ProvisionQLCore",
            dependencies: [
                "ZIPFoundation",
                "SwiftAXML",
                "SWCompression",
            ],
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
