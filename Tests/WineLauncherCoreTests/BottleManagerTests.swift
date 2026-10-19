import Foundation
import Testing
@testable import WineLauncherCore

struct BottleManagerTests {
    private let wine = URL(fileURLWithPath: "/opt/wine/bin/wine")
    private let dxvkURL = URL(string: "https://example.test/dxvk.tar.gz")!

    private struct Harness {
        let manager: BottleManager
        let store: FileBottleStore
        let launcher: RecordingLauncher
        let paths: AppPaths
    }

    private func makeHarness() throws -> Harness {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let store = FileBottleStore(root: paths.bottles)
        let launcher = RecordingLauncher()
        let dxvkArchive = try TestSupport.makeTarGz(files: [
            "dxvk-x/x64/d3d11.dll": "a", "dxvk-x/x64/d3d10core.dll": "b",
            "dxvk-x/x32/d3d11.dll": "c", "dxvk-x/x32/d3d10core.dll": "d",
        ])
        let manager = BottleManager(
            paths: paths, store: store, runtime: WineRuntime(wineExecutable: wine),
            launcher: launcher, downloader: FakeDownloader(fixtures: [dxvkURL: dxvkArchive]),
            extractor: TarArchiveExtractor(launcher: FoundationProcessLauncher()),
            dxvk: DXVKRelease(id: "t", archiveURL: dxvkURL))
        return Harness(manager: manager, store: store, launcher: launcher, paths: paths)
    }

    @Test func createBottleInitializesThePrefixAndSetsTheWindowsVersion() async throws {
        let h = try makeHarness()

        let bottle = try await h.manager.createBottle(name: "Steam", windowsVersion: .win11)

        #expect(try h.store.load(id: bottle.id).windowsVersion == .win11)
        #expect(h.launcher.commands.map(\.arguments) == [["wineboot", "--init"], ["winecfg", "-v", "win11"]])
        #expect(h.launcher.commands.allSatisfy { $0.environment["WINEPREFIX"] == h.store.prefixURL(for: bottle.id).path })
    }

    @Test func createBottleWithDxvkInstallsTheBackend() async throws {
        let h = try makeHarness()

        let bottle = try await h.manager.createBottle(name: "Games", backend: .dxvk)

        let dll = h.store.prefixURL(for: bottle.id).appendingPathComponent("drive_c/windows/system32/d3d11.dll")
        #expect(FileManager.default.fileExists(atPath: dll.path))
        #expect(try h.store.load(id: bottle.id).graphicsBackend == .dxvk)
    }

    @Test func createBottleRemovesTheBottleWhenInitializationFails() async throws {
        let h = try makeHarness()
        h.launcher.exitCode = 1

        await #expect(throws: BottleManagerError.self) {
            try await h.manager.createBottle(name: "Broken")
        }
        #expect(try h.store.list().isEmpty)
    }

    @Test func updateReappliesOnlyWhatChanged() async throws {
        let h = try makeHarness()
        var bottle = try await h.manager.createBottle(name: "Games")
        let before = h.launcher.commands.count

        bottle.windowsVersion = .win7
        bottle.environment["WINEESYNC"] = "1"
        try await h.manager.update(bottle)

        let added = h.launcher.commands.dropFirst(before).map(\.arguments)
        #expect(added == [["winecfg", "-v", "win7"]])
        #expect(try h.store.load(id: bottle.id).environment["WINEESYNC"] == "1")
    }

    @Test func leavingDxvkRestoresBuiltinDllsThroughWinebootUpdate() async throws {
        let h = try makeHarness()
        var bottle = try await h.manager.createBottle(name: "Games", backend: .dxvk)
        let before = h.launcher.commands.count

        bottle.graphicsBackend = .wineDefault
        try await h.manager.update(bottle)

        let dll = h.store.prefixURL(for: bottle.id).appendingPathComponent("drive_c/windows/system32/d3d11.dll")
        #expect(!FileManager.default.fileExists(atPath: dll.path))
        #expect(h.launcher.commands.dropFirst(before).map(\.arguments) == [["wineboot", "-u"]])
    }

    @Test func launchRunsTheProgramAndWritesALog() async throws {
        let h = try makeHarness()
        let bottle = try await h.manager.createBottle(name: "Games")

        let result = try await h.manager.launch(program: "C:\\game.exe", arguments: ["-w"], in: bottle)

        #expect(result.exitCode == 0)
        #expect(h.launcher.commands.last?.arguments == ["C:\\game.exe", "-w"])
        let logs = try FileManager.default.contentsOfDirectory(
            atPath: h.store.directory(for: bottle.id).appendingPathComponent("logs").path)
        #expect(logs.count == 1)
    }

    @Test func stopAllProgramsKillsTheWineserverOfTheBottle() async throws {
        let h = try makeHarness()
        let bottle = try await h.manager.createBottle(name: "Games")

        try await h.manager.stopAllPrograms(in: bottle)

        let last = h.launcher.commands.last
        #expect(last?.executable.lastPathComponent == "wineserver")
        #expect(last?.arguments == ["-k"])
        #expect(last?.environment["WINEPREFIX"] == h.store.prefixURL(for: bottle.id).path)
    }

    @Test func deleteRemovesTheBottle() async throws {
        let h = try makeHarness()
        let bottle = try await h.manager.createBottle(name: "Temp")

        try h.manager.delete(bottle)

        #expect(try h.store.list().isEmpty)
    }
}
