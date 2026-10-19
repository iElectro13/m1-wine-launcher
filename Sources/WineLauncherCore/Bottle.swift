import Foundation

public enum WindowsVersion: String, Codable, Sendable, CaseIterable {
    case win7
    case win10
    case win11
}

public enum GraphicsBackend: String, Codable, Sendable, CaseIterable {
    case wineDefault
    case dxvk
    case dxmt
    case d3dMetal
}

public enum DLLOverride: String, Codable, Sendable, CaseIterable {
    case native
    case builtin
    case nativeThenBuiltin
    case builtinThenNative
    case disabled
}

/// A program the user keeps handy in a bottle; `path` is a Windows or Unix path.
public struct PinnedProgram: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var path: String
    public var arguments: [String]

    public init(id: UUID = UUID(), name: String, path: String, arguments: [String] = []) {
        self.id = id
        self.name = name
        self.path = path
        self.arguments = arguments
    }
}

/// A Wine prefix plus the configuration used to launch programs inside it.
public struct Bottle: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var windowsVersion: WindowsVersion
    public var graphicsBackend: GraphicsBackend
    public var environment: [String: String]
    public var dllOverrides: [String: DLLOverride]
    public var pinnedPrograms: [PinnedProgram]

    public init(
        id: UUID = UUID(),
        name: String,
        windowsVersion: WindowsVersion = .win10,
        graphicsBackend: GraphicsBackend = .wineDefault,
        environment: [String: String] = [:],
        dllOverrides: [String: DLLOverride] = [:],
        pinnedPrograms: [PinnedProgram] = []
    ) {
        self.id = id
        self.name = name
        self.windowsVersion = windowsVersion
        self.graphicsBackend = graphicsBackend
        self.environment = environment
        self.dllOverrides = dllOverrides
        self.pinnedPrograms = pinnedPrograms
    }

    // Bottles saved before a field existed must keep loading.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        windowsVersion = try container.decode(WindowsVersion.self, forKey: .windowsVersion)
        graphicsBackend = try container.decode(GraphicsBackend.self, forKey: .graphicsBackend)
        environment = try container.decode([String: String].self, forKey: .environment)
        dllOverrides = try container.decode([String: DLLOverride].self, forKey: .dllOverrides)
        pinnedPrograms =
            try container.decodeIfPresent([PinnedProgram].self, forKey: .pinnedPrograms) ?? []
    }
}
