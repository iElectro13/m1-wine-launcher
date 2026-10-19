import Foundation

/// Where the app keeps everything it manages on disk.
public struct AppPaths: Sendable, Equatable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// `~/Library/Application Support/WineLauncher` on macOS.
    public static var `default`: AppPaths {
        let base =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return AppPaths(root: base.appendingPathComponent("WineLauncher", isDirectory: true))
    }

    public var bottles: URL { root.appendingPathComponent("Bottles", isDirectory: true) }
    public var runtimes: URL { root.appendingPathComponent("Runtimes", isDirectory: true) }
    public var downloads: URL { root.appendingPathComponent("Downloads", isDirectory: true) }
    public var cache: URL { root.appendingPathComponent("Cache", isDirectory: true) }
}
