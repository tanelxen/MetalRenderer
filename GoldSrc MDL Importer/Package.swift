// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "GoldSrcMDL",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "GoldSrcMDL",
            targets: ["GoldSrcMDL"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GoldSrcMDL",
            dependencies: ["SequencesEncoder"]
        ),
        .target(
            name: "SequencesEncoder",
            dependencies: []
        )
    ]
)
