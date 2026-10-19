import Foundation

public enum DiagnosticStatus: Sendable, Equatable {
    case ok
    case warning
    case failure
}

public struct DiagnosticItem: Sendable, Equatable {
    public let name: String
    public let status: DiagnosticStatus
    public let detail: String

    public init(name: String, status: DiagnosticStatus, detail: String) {
        self.name = name
        self.status = status
        self.detail = detail
    }
}

/// Checks that the machine can actually run the installed Wine runtime.
public struct Doctor: Sendable {
    private let runtime: WineRuntime
    private let launcher: any WineProcessLauncher

    public init(runtime: WineRuntime, launcher: any WineProcessLauncher) {
        self.runtime = runtime
        self.launcher = launcher
    }

    public func run() async -> [DiagnosticItem] {
        var items: [DiagnosticItem] = []
        #if os(macOS)
        items.append(await rosettaItem())
        #endif
        items.append(await wineItem())
        items.append(moltenVKItem())
        return items
    }

    #if os(macOS)
    private func rosettaItem() async -> DiagnosticItem {
        let command = WineCommand(
            executable: URL(fileURLWithPath: "/usr/bin/arch"), arguments: ["-x86_64", "/usr/bin/true"],
            environment: [:])
        if let result = try? await launcher.run(command), result.exitCode == 0 {
            return DiagnosticItem(name: "Rosetta 2", status: .ok, detail: "Installed")
        }
        return DiagnosticItem(
            name: "Rosetta 2", status: .failure,
            detail: "Install it with: softwareupdate --install-rosetta --agree-to-license")
    }
    #endif

    private func wineItem() async -> DiagnosticItem {
        guard FileManager.default.isExecutableFile(atPath: runtime.wineExecutable.path)
            || FileManager.default.fileExists(atPath: runtime.wineExecutable.path)
        else {
            return DiagnosticItem(name: "Wine", status: .failure, detail: "Wine executable not found")
        }
        let command = WineCommand(
            executable: runtime.wineExecutable, arguments: ["--version"], environment: [:])
        do {
            let result = try await launcher.run(command)
            guard result.exitCode == 0 else {
                return DiagnosticItem(
                    name: "Wine", status: .failure,
                    detail: "wine --version exited with \(result.exitCode)")
            }
            return DiagnosticItem(
                name: "Wine", status: .ok,
                detail: result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return DiagnosticItem(name: "Wine", status: .failure, detail: "\(error)")
        }
    }

    private func moltenVKItem() -> DiagnosticItem {
        let library = runtime.wineExecutable.deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("lib/libMoltenVK.dylib")
        if FileManager.default.fileExists(atPath: library.path) {
            return DiagnosticItem(name: "MoltenVK", status: .ok, detail: "Bundled with the runtime")
        }
        return DiagnosticItem(
            name: "MoltenVK", status: .warning,
            detail: "Not bundled; DXVK needs a Vulkan implementation")
    }
}
