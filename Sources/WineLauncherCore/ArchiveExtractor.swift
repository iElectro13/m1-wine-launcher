import Foundation

public enum ArchiveError: Error, Equatable {
    case extractionFailed(exitCode: Int32, message: String)
}

/// Port: unpacks an archive into a directory.
public protocol ArchiveExtractor: Sendable {
    func extract(_ archive: URL, to directory: URL) async throws
}

/// Adapter backed by the system `tar`, which detects gzip and xz on its own.
public struct TarArchiveExtractor: ArchiveExtractor {
    private let launcher: any WineProcessLauncher
    private let tar: URL

    public init(launcher: any WineProcessLauncher, tar: URL = URL(fileURLWithPath: "/usr/bin/tar")) {
        self.launcher = launcher
        self.tar = tar
    }

    public func extract(_ archive: URL, to directory: URL) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let result = try await launcher.run(
            WineCommand(
                executable: tar, arguments: ["-xf", archive.path, "-C", directory.path], environment: [:]))
        guard result.exitCode == 0 else {
            throw ArchiveError.extractionFailed(
                exitCode: result.exitCode,
                message: result.standardError.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
