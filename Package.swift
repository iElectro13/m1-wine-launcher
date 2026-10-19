// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WineLauncher",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WineLauncherCore", targets: ["WineLauncherCore"]),
    ],
    targets: [
        .target(name: "WineLauncherCore"),
        .testTarget(name: "WineLauncherCoreTests", dependencies: ["WineLauncherCore"]),
    ]
)
