import Foundation
@testable import WineLauncherCore

enum TestSupport {
    static func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wl-test-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Builds a `.tar.gz` whose entries are the given relative paths with the given contents.
    static func makeTarGz(files: [String: String]) throws -> URL {
        let staging = makeTempDirectory().appendingPathComponent("staging", isDirectory: true)
        for (path, contents) in files {
            let file = staging.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.write(to: file, atomically: true, encoding: .utf8)
        }
        let archive = makeTempDirectory().appendingPathComponent("fixture.tar.gz")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-czf", archive.path, "-C", staging.path, "."]
        try process.run()
        process.waitUntilExit()
        precondition(process.terminationStatus == 0, "tar fixture creation failed")
        return archive
    }
}

/// Downloader that serves local fixture files instead of touching the network.
final class FakeDownloader: Downloader, @unchecked Sendable {
    private let fixtures: [URL: URL]
    private(set) var requested: [URL] = []

    init(fixtures: [URL: URL]) {
        self.fixtures = fixtures
    }

    func download(
        from url: URL, to destination: URL, progress: (@Sendable (Double) -> Void)?
    ) async throws {
        requested.append(url)
        guard let fixture = fixtures[url] else { throw URLError(.fileDoesNotExist) }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.copyItem(at: fixture, to: destination)
        progress?(1)
    }
}

/// Launcher that records commands instead of running them.
final class RecordingLauncher: WineProcessLauncher, @unchecked Sendable {
    private(set) var commands: [WineCommand] = []
    var exitCode: Int32 = 0

    func run(_ command: WineCommand) async throws -> ProcessResult {
        commands.append(command)
        return ProcessResult(exitCode: exitCode, standardOutput: "", standardError: "")
    }
}
