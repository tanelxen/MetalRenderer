// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Quake3BSP",
    products: [
        .library(
            name: "Quake3BSP",
            targets: ["Quake3BSP"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Quake3BSP",
            dependencies: []),
    ]
)
