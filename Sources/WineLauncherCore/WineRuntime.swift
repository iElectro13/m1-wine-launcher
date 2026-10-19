import Foundation

/// An installed Wine distribution, identified by its `wine` executable.
public struct WineRuntime: Sendable, Equatable {
    public let wineExecutable: URL

    public init(wineExecutable: URL) {
        self.wineExecutable = wineExecutable
    }

    /// `wineserver` lives next to `wine` in every Wine distribution.
    public var wineserverExecutable: URL {
        wineExecutable.deletingLastPathComponent().appendingPathComponent("wineserver")
    }
}
