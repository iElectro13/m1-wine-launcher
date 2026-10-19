import Foundation
import Testing
@testable import WineLauncherCore

struct GraphicsBackendInstallerTests {
    private let release = DXVKRelease(
        id: "dxvk-test", archiveURL: URL(string: "https://example.test/dxvk.tar.gz")!)

    private let dxvkFiles = [
        "dxvk-x/x64/d3d11.dll": "x64-d3d11",
        "dxvk-x/x64/d3d10core.dll": "x64-d3d10core",
        "dxvk-x/x32/d3d11.dll": "x32-d3d11",
        "dxvk-x/x32/d3d10core.dll": "x32-d3d10core",
        "dxvk-x/dxvk.conf": "conf",
    ]

    private func makeInstaller(files: [String: String]) throws -> (
        GraphicsBackendInstaller, FakeDownloader, URL
    ) {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let downloader = FakeDownloader(fixtures: [release.archiveURL: try TestSupport.makeTarGz(files: files)])
        let installer = GraphicsBackendInstaller(
            paths: paths, downloader: downloader,
            extractor: TarArchiveExtractor(launcher: FoundationProcessLauncher()), dxvk: release)
        return (installer, downloader, TestSupport.makeTempDirectory().appendingPathComponent("prefix"))
    }

    private func read(_ prefix: URL, _ relative: String) -> String? {
        try? String(contentsOf: prefix.appendingPathComponent(relative), encoding: .utf8)
    }

    @Test func dxvkCopies64BitDllsToSystem32And32BitDllsToSyswow64() async throws {
        let (installer, _, prefix) = try makeInstaller(files: dxvkFiles)

        try await installer.apply(.dxvk, toPrefix: prefix)

        #expect(read(prefix, "drive_c/windows/system32/d3d11.dll") == "x64-d3d11")
        #expect(read(prefix, "drive_c/windows/system32/d3d10core.dll") == "x64-d3d10core")
        #expect(read(prefix, "drive_c/windows/syswow64/d3d11.dll") == "x32-d3d11")
        #expect(read(prefix, "drive_c/windows/syswow64/d3d10core.dll") == "x32-d3d10core")
    }

    @Test func dxvkArchiveIsDownloadedOnlyOnceAcrossPrefixes() async throws {
        let (installer, downloader, prefix) = try makeInstaller(files: dxvkFiles)
        let other = TestSupport.makeTempDirectory().appendingPathComponent("prefix2")

        try await installer.apply(.dxvk, toPrefix: prefix)
        try await installer.apply(.dxvk, toPrefix: other)

        #expect(downloader.requested.count == 1)
        #expect(read(other, "drive_c/windows/system32/d3d11.dll") == "x64-d3d11")
    }

    @Test func dxvkFailsWhenArchiveLacksTheExpectedFolders() async throws {
        let (installer, _, prefix) = try makeInstaller(files: ["dxvk-x/readme.txt": "nope"])

        await #expect(throws: GraphicsBackendError.dxvkFilesNotFound) {
            try await installer.apply(.dxvk, toPrefix: prefix)
        }
    }

    @Test func wineDefaultRemovesPreviouslyInstalledDxvkDlls() async throws {
        let (installer, _, prefix) = try makeInstaller(files: dxvkFiles)
        try await installer.apply(.dxvk, toPrefix: prefix)

        try await installer.apply(.wineDefault, toPrefix: prefix)

        #expect(read(prefix, "drive_c/windows/system32/d3d11.dll") == nil)
        #expect(read(prefix, "drive_c/windows/syswow64/d3d10core.dll") == nil)
    }

    @Test func wineDefaultOnACleanPrefixIsANoOp() async throws {
        let (installer, _, prefix) = try makeInstaller(files: dxvkFiles)

        try await installer.apply(.wineDefault, toPrefix: prefix)
    }

    @Test(arguments: [GraphicsBackend.dxmt, GraphicsBackend.d3dMetal])
    func unsupportedBackendsThrow(backend: GraphicsBackend) async throws {
        let (installer, _, prefix) = try makeInstaller(files: dxvkFiles)

        await #expect(throws: GraphicsBackendError.unsupported(backend)) {
            try await installer.apply(backend, toPrefix: prefix)
        }
    }
}
