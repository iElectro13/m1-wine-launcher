import Foundation
import Observation
import WineLauncherCore

enum RuntimeState: Equatable {
    case checking
    case notInstalled
    case installing(progress: Double)
    case ready
    case failed(String)
}

/// Everything the views observe, plus the operations they trigger.
/// Long operations run in tasks and publish their outcome back here.
@MainActor
@Observable
final class AppModel {
    private(set) var runtimeState: RuntimeState = .checking
    private(set) var bottles: [Bottle] = []
    var selectedBottleID: Bottle.ID?
    private(set) var busyMessage: String?
    var errorMessage: String?
    private(set) var diagnostics: [DiagnosticItem] = []
    private(set) var isRunningDiagnostics = false

    @ObservationIgnored private let paths: AppPaths
    @ObservationIgnored private let launcher = FoundationProcessLauncher()
    @ObservationIgnored private let downloader = URLSessionDownloader()
    @ObservationIgnored private let source = RuntimeSource.gcenx(.staging, version: "11.18")
    @ObservationIgnored private let installer: RuntimeInstaller
    @ObservationIgnored private var runtime: WineRuntime?
    @ObservationIgnored private var manager: BottleManager?
    // Bottle updates are applied in order so a slow one never races a later edit.
    @ObservationIgnored private var updateQueue: Task<Void, Never>?

    init(paths: AppPaths = .default) {
        self.paths = paths
        installer = RuntimeInstaller(
            paths: paths, downloader: downloader,
            extractor: TarArchiveExtractor(launcher: launcher))
    }

    var isBusy: Bool { busyMessage != nil }

    var selectedBottle: Bottle? {
        bottles.first { $0.id == selectedBottleID }
    }

    func logFiles(for bottle: Bottle) -> [URL] {
        manager?.logFiles(for: bottle) ?? []
    }

    // MARK: Runtime

    func bootstrap() async {
        runtimeState = .checking
        let installer = installer
        let source = source
        let existing = await Task.detached { installer.installedRuntime(for: source) }.value
        if let existing {
            activate(existing)
        } else {
            runtimeState = .notInstalled
        }
    }

    func installRuntime() {
        switch runtimeState {
        case .notInstalled, .failed: break
        case .checking, .installing, .ready: return
        }
        runtimeState = .installing(progress: 0)
        Task {
            do {
                let runtime = try await installer.install(source) { fraction in
                    Task { @MainActor in self.updateInstallProgress(fraction) }
                }
                activate(runtime)
            } catch {
                runtimeState = .failed(ErrorMessage.describe(error))
            }
        }
    }

    private func updateInstallProgress(_ fraction: Double) {
        // Progress callbacks can arrive after the install finished.
        guard case .installing = runtimeState else { return }
        runtimeState = .installing(progress: fraction)
    }

    private func activate(_ runtime: WineRuntime) {
        self.runtime = runtime
        manager = BottleManager(
            paths: paths, store: FileBottleStore(root: paths.bottles), runtime: runtime,
            launcher: launcher, downloader: downloader,
            extractor: TarArchiveExtractor(launcher: launcher))
        runtimeState = .ready
        reloadBottles()
    }

    // MARK: Bottles

    func createBottle(name: String, windowsVersion: WindowsVersion, backend: GraphicsBackend) {
        perform("Creating \(name)…") { manager in
            let bottle = try await manager.createBottle(
                name: name, windowsVersion: windowsVersion, backend: backend)
            self.reloadBottles()
            self.selectedBottleID = bottle.id
        }
    }

    func updateBottle(_ bottle: Bottle) {
        guard let manager, let index = bottles.firstIndex(where: { $0.id == bottle.id }) else { return }
        let previous = bottles[index]
        bottles[index] = bottle

        // Only these two settings make Wine touch the prefix, which can take a while.
        let touchesPrefix =
            previous.windowsVersion != bottle.windowsVersion
            || previous.graphicsBackend != bottle.graphicsBackend
        if touchesPrefix { busyMessage = "Applying settings to \(bottle.name)…" }

        let earlier = updateQueue
        updateQueue = Task {
            await earlier?.value
            do {
                try await manager.update(bottle)
            } catch {
                errorMessage = ErrorMessage.describe(error)
                reloadBottles()
            }
            if touchesPrefix { busyMessage = nil }
        }
    }

    func deleteBottle(_ bottle: Bottle) {
        perform("Deleting \(bottle.name)…") { manager in
            _ = try? await manager.stopAllPrograms(in: bottle)
            try await Task.detached { try manager.delete(bottle) }.value
            self.reloadBottles()
        }
    }

    private func reloadBottles() {
        guard let manager else { return }
        do {
            bottles = try manager.bottles()
        } catch {
            errorMessage = ErrorMessage.describe(error)
        }
        if !bottles.contains(where: { $0.id == selectedBottleID }) {
            selectedBottleID = bottles.first?.id
        }
    }

    // MARK: Programs

    func launch(_ program: String, arguments: [String] = [], in bottle: Bottle) {
        guard let manager else { return }
        Task {
            do {
                _ = try await manager.launch(program: program, arguments: arguments, in: bottle)
            } catch {
                errorMessage = ErrorMessage.describe(error)
            }
        }
    }

    func stopAll(in bottle: Bottle) {
        guard let manager else { return }
        Task {
            do {
                try await manager.stopAllPrograms(in: bottle)
            } catch {
                errorMessage = ErrorMessage.describe(error)
            }
        }
    }

    func installSteam(in bottle: Bottle) {
        perform("Installing Steam…") { manager in
            let updated = try await manager.installRecipe(.steam, in: bottle) { step in
                Task { @MainActor in self.updateBusyMessage("Installing Steam: \(step)…") }
            }
            if let index = self.bottles.firstIndex(where: { $0.id == updated.id }) {
                self.bottles[index] = updated
            }
        }
    }

    // MARK: Diagnostics

    func runDiagnostics() async {
        guard let runtime else { return }
        isRunningDiagnostics = true
        diagnostics = await Doctor(runtime: runtime, launcher: launcher).run()
        isRunningDiagnostics = false
    }

    // MARK: Helpers

    private func perform(
        _ message: String, _ operation: @escaping @MainActor (BottleManager) async throws -> Void
    ) {
        guard let manager, !isBusy else { return }
        busyMessage = message
        Task {
            do {
                try await operation(manager)
            } catch {
                errorMessage = ErrorMessage.describe(error)
            }
            busyMessage = nil
        }
    }

    private func updateBusyMessage(_ message: String) {
        // Progress callbacks can arrive after the operation finished.
        guard isBusy else { return }
        busyMessage = message
    }
}
