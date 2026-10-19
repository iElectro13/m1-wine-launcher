import Foundation

public enum BottleManagerError: Error, Equatable {
    case commandFailed(step: String, exitCode: Int32, message: String)
}

/// Application service: the operations the UI performs on bottles.
public struct BottleManager: Sendable {
    private let store: any BottleStore
    private let launcher: any WineProcessLauncher
    private let builder: WineCommandBuilder
    private let graphics: GraphicsBackendInstaller
    private let recipes: RecipeEngine

    public init(
        paths: AppPaths, store: any BottleStore, runtime: WineRuntime,
        launcher: any WineProcessLauncher, downloader: any Downloader, extractor: any ArchiveExtractor,
        dxvk: DXVKRelease = .macOSAsync
    ) {
        let builder = WineCommandBuilder(runtime: runtime)
        self.store = store
        self.launcher = launcher
        self.builder = builder
        self.graphics = GraphicsBackendInstaller(
            paths: paths, downloader: downloader, extractor: extractor, dxvk: dxvk)
        self.recipes = RecipeEngine(
            paths: paths, downloader: downloader, launcher: launcher, builder: builder)
    }

    public func bottles() throws -> [Bottle] {
        try store.list()
    }

    public func createBottle(
        name: String, windowsVersion: WindowsVersion = .win10, backend: GraphicsBackend = .wineDefault
    ) async throws -> Bottle {
        var bottle = try store.create(name: name)
        bottle.windowsVersion = windowsVersion
        bottle.graphicsBackend = backend
        let prefix = store.prefixURL(for: bottle.id)
        do {
            try await run(builder.initializePrefix(for: bottle, prefix: prefix), step: "Initialize prefix")
            try await run(builder.setWindowsVersion(for: bottle, prefix: prefix), step: "Set Windows version")
            try await graphics.apply(backend, toPrefix: prefix)
            try store.save(bottle)
        } catch {
            try? store.delete(id: bottle.id)
            throw error
        }
        return bottle
    }

    /// Persists the bottle and re-applies only the settings that changed on disk.
    public func update(_ bottle: Bottle) async throws {
        let previous = try store.load(id: bottle.id)
        let prefix = store.prefixURL(for: bottle.id)

        if previous.windowsVersion != bottle.windowsVersion {
            try await run(builder.setWindowsVersion(for: bottle, prefix: prefix), step: "Set Windows version")
        }
        if previous.graphicsBackend != bottle.graphicsBackend {
            try await graphics.apply(bottle.graphicsBackend, toPrefix: prefix)
            if previous.graphicsBackend == .dxvk {
                try await run(builder.updatePrefix(for: bottle, prefix: prefix), step: "Restore built-in DLLs")
            }
        }
        try store.save(bottle)
    }

    /// Runs a program to completion and keeps its output in the bottle's `logs` folder.
    public func launch(
        program: String, arguments: [String] = [], in bottle: Bottle
    ) async throws -> ProcessResult {
        let command = builder.launch(
            program: program, arguments: arguments, in: bottle, prefix: store.prefixURL(for: bottle.id))
        let result = try await launcher.run(command)
        writeLog(program: program, arguments: arguments, result: result, bottle: bottle)
        return result
    }

    /// Exit codes are ignored: `wineserver -k` fails when nothing is running, which is fine.
    public func stopAllPrograms(in bottle: Bottle) async throws {
        _ = try await launcher.run(builder.stopAll(prefix: store.prefixURL(for: bottle.id)))
    }

    public func installRecipe(
        _ recipe: Recipe, in bottle: Bottle, progress: @Sendable (String) -> Void
    ) async throws -> Bottle {
        let updated = try await recipes.run(
            recipe, on: bottle, prefix: store.prefixURL(for: bottle.id), progress: progress)
        try store.save(updated)
        return updated
    }

    public func delete(_ bottle: Bottle) throws {
        try store.delete(id: bottle.id)
    }

    private func run(_ command: WineCommand, step: String) async throws {
        let result = try await launcher.run(command)
        guard result.exitCode == 0 else {
            throw BottleManagerError.commandFailed(
                step: step, exitCode: result.exitCode,
                message: result.standardError.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func writeLog(program: String, arguments: [String], result: ProcessResult, bottle: Bottle) {
        let directory = store.directory(for: bottle.id).appendingPathComponent("logs", isDirectory: true)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let text = """
            $ \(([program] + arguments).joined(separator: " "))
            exit code: \(result.exitCode)

            --- stdout ---
            \(result.standardOutput)
            --- stderr ---
            \(result.standardError)
            """
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? text.write(
            to: directory.appendingPathComponent("\(formatter.string(from: Date())).log"),
            atomically: true, encoding: .utf8)
    }
}
