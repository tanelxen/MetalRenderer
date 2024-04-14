// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRecast",
    products: [
        .library(name: "RecastObjC", targets: ["RecastObjC"]),
        .library(name: "DetourPathfinder", targets: ["DetourPathfinder"])
    ],
    dependencies: [],
    targets: [
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
            name: "RecastObjC",
            dependencies: ["Recast", "Detour"],
            path: "Sources/RecastObjC",
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath(".")
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
        ),
        .target(
            name: "CDetour",
            dependencies: ["Detour"],
            path: "Sources/CDetour",
            publicHeadersPath: "Include",
            cxxSettings: [
                .headerSearchPath("Include")
            ]
        ),
        .target(
            name: "DetourPathfinder",
            dependencies: ["CDetour"],
            path: "Sources/DetourPathfinder"
        ),
    ],
    cxxLanguageStandard: .cxx11
)
