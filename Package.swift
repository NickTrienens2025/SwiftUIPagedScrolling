// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "SwiftUIPagedScrolling",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "SwiftUIPagedScrolling",
            targets: ["SwiftUIPagedScrolling"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftUIPagedScrolling"
        ),
        .testTarget(
            name: "SwiftUIPagedScrollingTests",
            dependencies: ["SwiftUIPagedScrolling"]
        ),
    ]
)
