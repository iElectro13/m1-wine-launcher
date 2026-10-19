import SwiftUI
import WineLauncherCore

struct BottleDetailView: View {
    let model: AppModel
    let bottle: Bottle

    @State private var tab = Tab.general

    private enum Tab: String, CaseIterable, Identifiable {
        case general = "General"
        case environment = "Environment"
        case dllOverrides = "DLL Overrides"
        case programs = "Programs"
        case logs = "Logs"

        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            Divider()

            content
                .id(bottle.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(bottle.name)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .general:
            GeneralTab(
                windowsVersion: bottle.windowsVersion,
                graphicsBackend: bottle.graphicsBackend,
                onWindowsVersionChange: { version in edit { $0.windowsVersion = version } },
                onGraphicsBackendChange: { backend in edit { $0.graphicsBackend = backend } })
        case .environment:
            EnvironmentTab(
                environment: bottle.environment,
                onChange: { environment in edit { $0.environment = environment } })
        case .dllOverrides:
            DLLOverridesTab(
                overrides: bottle.dllOverrides,
                onChange: { overrides in edit { $0.dllOverrides = overrides } })
        case .programs:
            ProgramsTab(
                programs: bottle.pinnedPrograms,
                isBusy: model.isBusy,
                onRun: { program in
                    model.launch(program.path, arguments: program.arguments, in: bottle)
                },
                onRemove: { program in edit { $0.pinnedPrograms.removeAll { $0.id == program.id } } },
                onRunExecutable: runExecutable,
                onInstallSteam: { model.installSteam(in: bottle) },
                onRunTool: { model.launch($0, in: bottle) },
                onStopAll: { model.stopAll(in: bottle) })
        case .logs:
            LogsTab(loadLogFiles: { model.logFiles(for: bottle) })
        }
    }

    private func edit(_ change: (inout Bottle) -> Void) {
        var updated = bottle
        change(&updated)
        model.updateBottle(updated)
    }

    private func runExecutable() {
        guard let url = ExecutablePanel.choose() else { return }
        model.launch(url.path, in: bottle)
    }
}
