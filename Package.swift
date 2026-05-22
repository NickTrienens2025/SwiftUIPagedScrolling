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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
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
