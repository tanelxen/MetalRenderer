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
        ),
//        .executable(
//            name: "TestApp",
//            targets: ["TestApp"]
//        )
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
        ),
        .executableTarget(
            name: "TestApp",
            dependencies: ["GoldSrcMDL"],
            resources: [.copy("Assets/")]
        )
    ]
)
