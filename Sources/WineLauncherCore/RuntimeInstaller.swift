import Foundation

public enum RuntimeInstallerError: Error, Equatable {
    case wineExecutableNotFound
}

/// A downloadable Wine distribution.
public struct RuntimeSource: Sendable, Equatable {
    public enum Variant: String, Sendable {
        case devel
        case staging
    }

    public let id: String
    public let archiveURL: URL

    public init(id: String, archiveURL: URL) {
        self.id = id
        self.archiveURL = archiveURL
    }

    /// Upstream WineHQ builds packaged for macOS by Gcenx (x86_64, runs through Rosetta 2).
    public static func gcenx(_ variant: Variant, version: String) -> RuntimeSource {
        let name = "wine-\(variant.rawValue)-\(version)"
        let url = URL(
            string:
                "https://github.com/Gcenx/macOS_Wine_builds/releases/download/\(version)/\(name)-osx64.tar.xz"
        )!
        return RuntimeSource(id: name, archiveURL: url)
    }
}

public struct RuntimeInstaller: Sendable {
    private let paths: AppPaths
    private let downloader: any Downloader
    private let extractor: any ArchiveExtractor

    public init(paths: AppPaths, downloader: any Downloader, extractor: any ArchiveExtractor) {
        self.paths = paths
        self.downloader = downloader
        self.extractor = extractor
    }

    private func installDirectory(for source: RuntimeSource) -> URL {
        paths.runtimes.appendingPathComponent(source.id, isDirectory: true)
    }

    public func installedRuntime(for source: RuntimeSource) -> WineRuntime? {
        Self.findWine(in: installDirectory(for: source)).map(WineRuntime.init(wineExecutable:))
    }

    public func install(
        _ source: RuntimeSource, progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> WineRuntime {
        if let existing = installedRuntime(for: source) { return existing }

        let fileManager = FileManager.default
        let archive = paths.downloads.appendingPathComponent(source.archiveURL.lastPathComponent)
        let staging = paths.runtimes.appendingPathComponent("\(source.id).partial", isDirectory: true)
        let final = installDirectory(for: source)
        defer {
            try? fileManager.removeItem(at: archive)
            try? fileManager.removeItem(at: staging)
        }

        try await downloader.download(from: source.archiveURL, to: archive, progress: progress)
        try? fileManager.removeItem(at: staging)
        try await extractor.extract(archive, to: staging)
        guard Self.findWine(in: staging) != nil else {
            throw RuntimeInstallerError.wineExecutableNotFound
        }

        try? fileManager.removeItem(at: final)
        try fileManager.moveItem(at: staging, to: final)
        guard let wine = Self.findWine(in: final) else {
            throw RuntimeInstallerError.wineExecutableNotFound
        }
        return WineRuntime(wineExecutable: wine)
    }

    /// Finds `bin/wine` inside an extracted distribution, whatever the bundle layout above it.
    private static func findWine(in directory: URL) -> URL? {
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: nil)
        else { return nil }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.lastPathComponent == "wine" && $0.deletingLastPathComponent().lastPathComponent == "bin" }
            .min { $0.path.count < $1.path.count }
    }
}
