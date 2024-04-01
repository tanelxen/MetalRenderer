// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftBullet",
    products: [
        .library(name: "SwiftBullet", targets: ["SwiftBullet"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftBullet",
            dependencies: ["ObjCBullet"],
            path: "Sources/SwiftBullet"
        ),
        .target(
            name: "ObjCBullet",
            dependencies: ["bullet", "DynamicCharacter"],
            path: "Sources/ObjCBullet",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
        .target(
            name: "bullet",
            dependencies: [],
            path: "Sources/bullet-2.87",
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath(".")
            ]
        ),
        .target(
            name: "DynamicCharacter",
            dependencies: ["bullet"],
            path: "Sources/DynamicCharacter",
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath(".")
            ]
        )
    ],
    cxxLanguageStandard: .cxx11
)
