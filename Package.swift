// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetaHangulIME",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "MetaHangulIME",
            targets: ["MetaHangulIME"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "MetaHangulIME",
            dependencies: ["Yams"],
            resources: [
                .copy("Resources/IMEConfigurations")
            ]),
        .testTarget(
            name: "MetaHangulIMETests",
            dependencies: ["MetaHangulIME"]),
    ]
)