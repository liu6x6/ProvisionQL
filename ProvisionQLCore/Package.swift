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
        .package(url: "https://github.com/liu6x6/SwiftAXML.git", revision: "b7e8b99a141fc82da444423731b8b71588d6b6d0")
    ],
    targets: [
        .target(
            name: "UnrarKit",
            path: "Sources/UnrarKit",
            
            publicHeadersPath: "include",
            cxxSettings: [
                .define("RARDLL"),
                .define("SILENT"),
                .define("UNRAR"),
                .define("_APPLE"),
                .define("_UNIX")
            ]
        ),
        .target(
            name: "ProvisionQLCore",
            dependencies: [
                "ZIPFoundation",
                "SwiftAXML",
                "SWCompression"
            ],
            path: "Sources",
            exclude: ["UnrarKit"],
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
