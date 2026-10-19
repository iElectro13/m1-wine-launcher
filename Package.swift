// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = [
    .library(name: "WineLauncherCore", targets: ["WineLauncherCore"]),
]

var targets: [Target] = [
    .target(name: "WineLauncherCore"),
    .testTarget(name: "WineLauncherCoreTests", dependencies: ["WineLauncherCore"]),
]

// The SwiftUI app only exists on macOS; the core stays buildable and testable on Linux.
#if os(macOS)
products.append(.executable(name: "WineLauncher", targets: ["WineLauncher"]))
targets.append(.executableTarget(name: "WineLauncher", dependencies: ["WineLauncherCore"]))
#endif

let package = Package(
    name: "WineLauncher",
    platforms: [.macOS(.v14)],
    products: products,
    targets: targets
)
