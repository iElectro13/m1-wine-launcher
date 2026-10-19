import Foundation
import Testing
@testable import WineLauncherCore

struct RuntimeInstallerTests {
    private let source = RuntimeSource.gcenx(.staging, version: "11.18")
    private let wineRelativePath = "Wine Staging.app/Contents/Resources/wine/bin/wine"

    private func makeInstaller(
        archiveFiles: [String: String]
    ) throws -> (RuntimeInstaller, FakeDownloader, AppPaths) {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let archive = try TestSupport.makeTarGz(files: archiveFiles)
        let downloader = FakeDownloader(fixtures: [source.archiveURL: archive])
        let installer = RuntimeInstaller(
            paths: paths, downloader: downloader,
            extractor: TarArchiveExtractor(launcher: FoundationProcessLauncher()))
        return (installer, downloader, paths)
    }

    @Test func gcenxSourceBuildsTheReleaseUrl() {
        #expect(
            source.archiveURL.absoluteString
                == "https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.18/wine-staging-11.18-osx64.tar.xz"
        )
        #expect(source.id == "wine-staging-11.18")
    }

    @Test func installDownloadsExtractsAndLocatesTheWineExecutable() async throws {
        let (installer, _, paths) = try makeInstaller(archiveFiles: [wineRelativePath: "#!/bin/sh\n"])

        let runtime = try await installer.install(source)

        #expect(runtime.wineExecutable.path.hasSuffix(wineRelativePath))
        #expect(runtime.wineExecutable.path.hasPrefix(paths.runtimes.path))
        #expect(FileManager.default.fileExists(atPath: runtime.wineExecutable.path))
    }

    @Test func installDeletesTheDownloadedArchive() async throws {
        let (installer, _, paths) = try makeInstaller(archiveFiles: [wineRelativePath: "x"])

        _ = try await installer.install(source)

        let leftovers = (try? FileManager.default.contentsOfDirectory(atPath: paths.downloads.path)) ?? []
        #expect(leftovers.isEmpty)
    }

    @Test func installIsIdempotentAndSkipsTheSecondDownload() async throws {
        let (installer, downloader, _) = try makeInstaller(archiveFiles: [wineRelativePath: "x"])

        let first = try await installer.install(source)
        let second = try await installer.install(source)

        #expect(first == second)
        #expect(downloader.requested.count == 1)
    }

    @Test func installedRuntimeIsNilBeforeInstallAndSetAfter() async throws {
        let (installer, _, _) = try makeInstaller(archiveFiles: [wineRelativePath: "x"])

        #expect(installer.installedRuntime(for: source) == nil)
        let runtime = try await installer.install(source)
        #expect(installer.installedRuntime(for: source) == runtime)
    }

    @Test func installFailsWhenArchiveHasNoWineBinaryAndLeavesNothingInstalled() async throws {
        let (installer, _, _) = try makeInstaller(archiveFiles: ["README.txt": "nothing"])

        await #expect(throws: RuntimeInstallerError.wineExecutableNotFound) {
            try await installer.install(source)
        }
        #expect(installer.installedRuntime(for: source) == nil)
    }
}
