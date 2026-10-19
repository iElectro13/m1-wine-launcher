import Foundation

public enum GraphicsBackendError: Error, Equatable {
    case unsupported(GraphicsBackend)
    case dxvkFilesNotFound
}

/// A DXVK build for macOS (runs on top of MoltenVK, which the Wine runtime bundles).
public struct DXVKRelease: Sendable, Equatable {
    public let id: String
    public let archiveURL: URL

    public init(id: String, archiveURL: URL) {
        self.id = id
        self.archiveURL = archiveURL
    }

    public static let macOSAsync = DXVKRelease(
        id: "dxvk-macOS-async-v1.10.3-20230507-repack",
        archiveURL: URL(
            string:
                "https://github.com/Gcenx/DXVK-macOS/releases/download/v1.10.3-20230507-repack/dxvk-macOS-async-v1.10.3-20230507-repack.tar.gz"
        )!)
}

/// Installs or removes the DLLs a graphics backend needs inside a Wine prefix.
public struct GraphicsBackendInstaller: Sendable {
    private static let dxvkDllNames = ["d3d10core.dll", "d3d11.dll"]

    private let paths: AppPaths
    private let downloader: any Downloader
    private let extractor: any ArchiveExtractor
    private let dxvk: DXVKRelease

    public init(
        paths: AppPaths, downloader: any Downloader, extractor: any ArchiveExtractor,
        dxvk: DXVKRelease = .macOSAsync
    ) {
        self.paths = paths
        self.downloader = downloader
        self.extractor = extractor
        self.dxvk = dxvk
    }

    public func apply(_ backend: GraphicsBackend, toPrefix prefix: URL) async throws {
        switch backend {
        case .wineDefault:
            removeDXVK(from: prefix)
        case .dxvk:
            try await installDXVK(into: prefix)
        case .dxmt, .d3dMetal:
            throw GraphicsBackendError.unsupported(backend)
        }
    }

    private func system32(_ prefix: URL) -> URL {
        prefix.appendingPathComponent("drive_c/windows/system32", isDirectory: true)
    }

    private func syswow64(_ prefix: URL) -> URL {
        prefix.appendingPathComponent("drive_c/windows/syswow64", isDirectory: true)
    }

    private func removeDXVK(from prefix: URL) {
        for directory in [system32(prefix), syswow64(prefix)] {
            for name in Self.dxvkDllNames {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
            }
        }
    }

    private func installDXVK(into prefix: URL) async throws {
        let cached = try await cachedDXVK()
        guard let x64 = Self.findDirectory(named: "x64", in: cached) else {
            throw GraphicsBackendError.dxvkFilesNotFound
        }
        try copyDlls(from: x64, to: system32(prefix))
        if let x32 = Self.findDirectory(named: "x32", in: cached) {
            try copyDlls(from: x32, to: syswow64(prefix))
        }
    }

    /// Downloads and unpacks the release once; later prefixes reuse the extracted copy.
    private func cachedDXVK() async throws -> URL {
        let fileManager = FileManager.default
        let final = paths.cache.appendingPathComponent(dxvk.id, isDirectory: true)
        if fileManager.fileExists(atPath: final.path) { return final }

        let archive = paths.downloads.appendingPathComponent(dxvk.archiveURL.lastPathComponent)
        let staging = paths.cache.appendingPathComponent("\(dxvk.id).partial", isDirectory: true)
        defer {
            try? fileManager.removeItem(at: archive)
            try? fileManager.removeItem(at: staging)
        }
        try await downloader.download(from: dxvk.archiveURL, to: archive, progress: nil)
        try? fileManager.removeItem(at: staging)
        try await extractor.extract(archive, to: staging)
        guard Self.findDirectory(named: "x64", in: staging) != nil else {
            throw GraphicsBackendError.dxvkFilesNotFound
        }
        try fileManager.moveItem(at: staging, to: final)
        return final
    }

    private func copyDlls(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let dlls = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "dll" }
        for dll in dlls {
            let target = destination.appendingPathComponent(dll.lastPathComponent)
            try? fileManager.removeItem(at: target)
            try fileManager.copyItem(at: dll, to: target)
        }
    }

    private static func findDirectory(named name: String, in root: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.isDirectoryKey])
        else { return nil }
        return enumerator.compactMap { $0 as? URL }
            .first {
                $0.lastPathComponent == name
                    && (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
    }
}
