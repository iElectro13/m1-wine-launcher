import Foundation

public enum RecipeStep: Codable, Sendable, Equatable {
    case download(url: URL, fileName: String)
    case runDownloaded(fileName: String, arguments: [String])
    case setEnvironment(key: String, value: String)
    case pinProgram(name: String, path: String, arguments: [String])
}

/// A declarative installer: an ordered list of steps applied to a bottle.
public struct Recipe: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let steps: [RecipeStep]

    public init(id: String, name: String, steps: [RecipeStep]) {
        self.id = id
        self.name = name
        self.steps = steps
    }

    public static let steam = Recipe(
        id: "steam",
        name: "Steam",
        steps: [
            .download(
                url: URL(string: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe")!,
                fileName: "SteamSetup.exe"),
            .runDownloaded(fileName: "SteamSetup.exe", arguments: ["/S"]),
            .pinProgram(
                name: "Steam", path: "C:\\Program Files (x86)\\Steam\\steam.exe",
                arguments: ["-no-cef-sandbox"]),
        ])
}
