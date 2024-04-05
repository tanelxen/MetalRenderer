// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRecast",
    products: [
        .library(name: "SwiftRecast", targets: ["RecastObjC"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RecastObjC",
            dependencies: ["Recast", "Detour"],
            path: "Sources/RecastObjC",
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
        .target(
            name: "Recast",
            dependencies: [],
            path: "Sources/Recast",
            publicHeadersPath: "Include",
            cxxSettings: [
                .headerSearchPath("Include")
            ]
        ),
        .target(
            name: "Detour",
            dependencies: [],
            path: "Sources/Detour",
            publicHeadersPath: "Include",
            cxxSettings: [
                .headerSearchPath("Include")
            ]
        )
    ],
    cxxLanguageStandard: .cxx11
)
