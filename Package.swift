// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGenie",
    platforms: [.macOS(.v15)],
        dependencies: [
            .package(
                url: "https://github.com/apple/swift-argument-parser.git",
                from: "1.5.0"
            ),
            .package(
                url: "https://github.com/jpsim/Yams.git",
                from: "5.3.1"
            )
        ],
        targets: [
            .executableTarget(
                name: "SwiftGenie",
                dependencies: [
                    .product(name: "ArgumentParser", package: "swift-argument-parser"),
                    "Yams"
                ],
                path: "Sources/SwiftGenie"
            )
        ]
)
