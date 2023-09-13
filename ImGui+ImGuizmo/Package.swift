// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "ImGui+ImGuizmo",
    products: [
        .library(name: "ImGui", targets: ["ImGui"]),
        .library(name: "ImGuizmo", targets: ["ImGuizmo"])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "ImGui", dependencies: ["CImGui"]),
        .target(name: "CImGui",
                path: "Sources/CImGui", //1.86-docking
                cSettings: [.define("CIMGUI_DEFINE_ENUMS_AND_STRUCTS")],
                cxxSettings: [.define("CIMGUI_DEFINE_ENUMS_AND_STRUCTS")]),
        .target(name: "ImGuizmo", dependencies: [.byName(name: "CImGuizmo")]),
        .target(name: "CImGuizmo", dependencies: [.byName(name: "ImGui")]),
    ],
    cxxLanguageStandard: .cxx11
)
