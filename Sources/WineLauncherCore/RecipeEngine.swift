import Foundation

public enum RecipeError: Error, Equatable {
    case stepFailed(index: Int, exitCode: Int32, message: String)
    case invalidFileName(String)
}

public struct RecipeEngine: Sendable {
    private let paths: AppPaths
    private let downloader: any Downloader
    private let launcher: any WineProcessLauncher
    private let builder: WineCommandBuilder

    public init(
        paths: AppPaths, downloader: any Downloader, launcher: any WineProcessLauncher,
        builder: WineCommandBuilder
    ) {
        self.paths = paths
        self.downloader = downloader
        self.launcher = launcher
        self.builder = builder
    }

    private var recipeDownloads: URL {
        paths.downloads.appendingPathComponent("recipes", isDirectory: true)
    }

    /// Applies the recipe and returns the updated bottle; the caller decides when to persist it.
    public func run(
        _ recipe: Recipe, on bottle: Bottle, prefix: URL,
        progress: @Sendable (String) -> Void
    ) async throws -> Bottle {
        var bottle = bottle
        for (index, step) in recipe.steps.enumerated() {
            switch step {
            case .download(let url, let fileName):
                progress("Downloading \(fileName)")
                let destination = try downloadLocation(for: fileName)
                try await downloader.download(from: url, to: destination, progress: nil)

            case .runDownloaded(let fileName, let arguments):
                progress("Running \(fileName)")
                let file = try downloadLocation(for: fileName)
                let result = try await launcher.run(
                    builder.launch(program: file.path, arguments: arguments, in: bottle, prefix: prefix))
                guard result.exitCode == 0 else {
                    throw RecipeError.stepFailed(
                        index: index, exitCode: result.exitCode,
                        message: result.standardError.trimmingCharacters(in: .whitespacesAndNewlines))
                }

            case .setEnvironment(let key, let value):
                progress("Setting \(key)")
                bottle.environment[key] = value

            case .pinProgram(let name, let path, let arguments):
                progress("Adding \(name)")
                bottle.pinnedPrograms.removeAll { $0.name == name }
                bottle.pinnedPrograms.append(PinnedProgram(name: name, path: path, arguments: arguments))
            }
        }
        return bottle
    }

    /// Recipes may come from user-supplied JSON, so file names must not escape the downloads folder.
    private func downloadLocation(for fileName: String) throws -> URL {
        guard !fileName.isEmpty, !fileName.contains("/"), !fileName.contains("\\"), fileName != "..", fileName != "."
        else { throw RecipeError.invalidFileName(fileName) }
        return recipeDownloads.appendingPathComponent(fileName)
    }
}
