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

/// A Wine prefix plus the configuration used to launch programs inside it.
public struct Bottle: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var windowsVersion: WindowsVersion
    public var graphicsBackend: GraphicsBackend
    public var environment: [String: String]
    public var dllOverrides: [String: DLLOverride]

    public init(
        id: UUID = UUID(),
        name: String,
        windowsVersion: WindowsVersion = .win10,
        graphicsBackend: GraphicsBackend = .wineDefault,
        environment: [String: String] = [:],
        dllOverrides: [String: DLLOverride] = [:]
    ) {
        self.id = id
        self.name = name
        self.windowsVersion = windowsVersion
        self.graphicsBackend = graphicsBackend
        self.environment = environment
        self.dllOverrides = dllOverrides
    }
}
