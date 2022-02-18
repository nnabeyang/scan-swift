// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "scan-swift",
    products: [
        .library(
            name: "ScanSwift",
            targets: ["ScanSwift"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ScanSwift",
            dependencies: []),
        .testTarget(
            name: "ScanSwiftTests",
            dependencies: ["ScanSwift"]),
    ]
)
