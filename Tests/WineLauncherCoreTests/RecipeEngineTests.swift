import Foundation
import Testing
@testable import WineLauncherCore

struct RecipeEngineTests {
    private let wine = URL(fileURLWithPath: "/opt/wine/bin/wine")
    private let prefix = URL(fileURLWithPath: "/bottles/abc/prefix")
    private let installerURL = URL(string: "https://example.test/Setup.exe")!

    private func makeEngine(
        launcher: RecordingLauncher, paths: AppPaths
    ) throws -> RecipeEngine {
        let setup = TestSupport.makeTempDirectory().appendingPathComponent("Setup.exe")
        try "binary".write(to: setup, atomically: true, encoding: .utf8)
        return RecipeEngine(
            paths: paths,
            downloader: FakeDownloader(fixtures: [installerURL: setup]),
            launcher: launcher,
            builder: WineCommandBuilder(runtime: WineRuntime(wineExecutable: wine)))
    }

    @Test func steamRecipeDownloadsInstallsSilentlyAndPinsSteam() {
        let steps = Recipe.steam.steps

        #expect(
            steps.first
                == .download(
                    url: URL(string: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe")!,
                    fileName: "SteamSetup.exe"))
        #expect(steps.contains(.runDownloaded(fileName: "SteamSetup.exe", arguments: ["/S"])))
        #expect(
            steps.contains(
                .pinProgram(
                    name: "Steam", path: "C:\\Program Files (x86)\\Steam\\steam.exe",
                    arguments: ["-no-cef-sandbox"])))
    }

    @Test func recipesRoundTripThroughJson() throws {
        let data = try JSONEncoder().encode(Recipe.steam)

        #expect(try JSONDecoder().decode(Recipe.self, from: data) == Recipe.steam)
    }

    @Test func runExecutesStepsInOrderAgainstTheBottlePrefix() async throws {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let launcher = RecordingLauncher()
        let engine = try makeEngine(launcher: launcher, paths: paths)
        let recipe = Recipe(
            id: "t", name: "Test",
            steps: [
                .download(url: installerURL, fileName: "Setup.exe"),
                .runDownloaded(fileName: "Setup.exe", arguments: ["/S"]),
                .setEnvironment(key: "FOO", value: "bar"),
                .pinProgram(name: "App", path: "C:\\app.exe", arguments: ["-x"]),
            ])

        let result = try await engine.run(recipe, on: Bottle(name: "B"), prefix: prefix) { _ in }

        let downloaded = paths.downloads.appendingPathComponent("recipes/Setup.exe").path
        #expect(FileManager.default.fileExists(atPath: downloaded))
        #expect(launcher.commands.count == 1)
        #expect(launcher.commands[0].arguments == [downloaded, "/S"])
        #expect(launcher.commands[0].environment["WINEPREFIX"] == prefix.path)
        #expect(result.environment["FOO"] == "bar")
        #expect(result.pinnedPrograms.map(\.name) == ["App"])
        #expect(result.pinnedPrograms[0].path == "C:\\app.exe")
        #expect(result.pinnedPrograms[0].arguments == ["-x"])
    }

    @Test func pinningTheSameProgramTwiceReplacesTheEntry() async throws {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let engine = try makeEngine(launcher: RecordingLauncher(), paths: paths)
        let recipe = Recipe(
            id: "t", name: "Test",
            steps: [
                .pinProgram(name: "App", path: "C:\\app.exe", arguments: []),
                .pinProgram(name: "App", path: "C:\\app.exe", arguments: ["-new"]),
            ])

        let result = try await engine.run(recipe, on: Bottle(name: "B"), prefix: prefix) { _ in }

        #expect(result.pinnedPrograms.count == 1)
        #expect(result.pinnedPrograms[0].arguments == ["-new"])
    }

    @Test func nonZeroExitStopsTheRecipeAndReportsTheStep() async throws {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let launcher = RecordingLauncher()
        launcher.exitCode = 5
        let engine = try makeEngine(launcher: launcher, paths: paths)
        let recipe = Recipe(
            id: "t", name: "Test",
            steps: [
                .download(url: installerURL, fileName: "Setup.exe"),
                .runDownloaded(fileName: "Setup.exe", arguments: []),
                .pinProgram(name: "App", path: "C:\\app.exe", arguments: []),
            ])

        await #expect(throws: RecipeError.stepFailed(index: 1, exitCode: 5, message: "")) {
            try await engine.run(recipe, on: Bottle(name: "B"), prefix: prefix) { _ in }
        }
    }

    @Test func runReportsOneProgressMessagePerStep() async throws {
        let paths = AppPaths(root: TestSupport.makeTempDirectory())
        let engine = try makeEngine(launcher: RecordingLauncher(), paths: paths)
        let messages = LockedBox<[String]>([])

        _ = try await engine.run(
            Recipe(
                id: "t", name: "Test",
                steps: [
                    .download(url: installerURL, fileName: "Setup.exe"),
                    .runDownloaded(fileName: "Setup.exe", arguments: []),
                ]),
            on: Bottle(name: "B"), prefix: prefix
        ) { messages.value.append($0) }

        #expect(messages.value.count == 2)
    }
}
