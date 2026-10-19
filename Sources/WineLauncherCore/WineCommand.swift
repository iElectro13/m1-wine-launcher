import Foundation

/// A process invocation: what to run and the variables to add to the inherited environment.
public struct WineCommand: Sendable, Equatable {
    public let executable: URL
    public let arguments: [String]
    public let environment: [String: String]

    public init(executable: URL, arguments: [String], environment: [String: String]) {
        self.executable = executable
        self.arguments = arguments
        self.environment = environment
    }
}

/// Pure translation of a bottle's configuration into Wine invocations.
public struct WineCommandBuilder: Sendable {
    private let runtime: WineRuntime

    public init(runtime: WineRuntime) {
        self.runtime = runtime
    }

    public func launch(
        program: String, arguments: [String] = [], in bottle: Bottle, prefix: URL
    ) -> WineCommand {
        command([program] + arguments, bottle: bottle, prefix: prefix)
    }

    public func initializePrefix(for bottle: Bottle, prefix: URL) -> WineCommand {
        command(["wineboot", "--init"], bottle: bottle, prefix: prefix)
    }

    public func setWindowsVersion(for bottle: Bottle, prefix: URL) -> WineCommand {
        command(["winecfg", "-v", bottle.windowsVersion.rawValue], bottle: bottle, prefix: prefix)
    }

    private func command(_ arguments: [String], bottle: Bottle, prefix: URL) -> WineCommand {
        var environment = ["WINEDEBUG": "-all"]
        environment.merge(bottle.environment) { _, bottleValue in bottleValue }
        environment["WINEPREFIX"] = prefix.path
        if let overrides = dllOverridesValue(for: bottle) {
            environment["WINEDLLOVERRIDES"] = overrides
        }
        return WineCommand(
            executable: runtime.wineExecutable, arguments: arguments, environment: environment)
    }

    private func dllOverridesValue(for bottle: Bottle) -> String? {
        var overrides = bottle.graphicsBackend.dllOverrides
        overrides.merge(bottle.dllOverrides) { _, bottleValue in bottleValue }
        guard !overrides.isEmpty else { return nil }
        return overrides.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.wineModeCode)" }
            .joined(separator: ";")
    }
}

extension GraphicsBackend {
    /// DLL overrides a backend needs. Backends not listed here have no overrides yet.
    fileprivate var dllOverrides: [String: DLLOverride] {
        switch self {
        case .dxvk:
            ["d3d10core": .nativeThenBuiltin, "d3d11": .nativeThenBuiltin]
        case .wineDefault, .dxmt, .d3dMetal:
            [:]
        }
    }
}

extension DLLOverride {
    /// Encoding used inside `WINEDLLOVERRIDES`.
    fileprivate var wineModeCode: String {
        switch self {
        case .native: "n"
        case .builtin: "b"
        case .nativeThenBuiltin: "n,b"
        case .builtinThenNative: "b,n"
        case .disabled: ""
        }
    }
}
