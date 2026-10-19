import SwiftUI
import WineLauncherCore

struct ProgramsTab: View {
    let programs: [PinnedProgram]
    let isBusy: Bool
    let onRun: (PinnedProgram) -> Void
    let onRemove: (PinnedProgram) -> Void
    let onRunExecutable: () -> Void
    let onInstallSteam: () -> Void
    let onRunTool: (String) -> Void
    let onStopAll: () -> Void

    private struct Tool: Identifiable {
        let title: String
        let program: String
        let symbol: String
        var id: String { program }
    }

    private static let tools = [
        Tool(title: "Wine Configuration", program: "winecfg", symbol: "gearshape"),
        Tool(title: "Registry Editor", program: "regedit", symbol: "list.bullet.rectangle"),
        Tool(title: "Task Manager", program: "taskmgr", symbol: "chart.bar"),
    ]

    private var steamInstalled: Bool {
        programs.contains { $0.name == Recipe.steam.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: onInstallSteam) {
                    Label(
                        steamInstalled ? "Steam Installed" : "Install Steam",
                        systemImage: steamInstalled ? "checkmark.circle" : "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(steamInstalled || isBusy)

                Spacer()

                Button("Run .exe…", systemImage: "play.rectangle", action: onRunExecutable)
            }

            GroupBox("Pinned programs") {
                if programs.isEmpty {
                    Text("Nothing pinned yet. Install Steam or run an .exe to get started.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    List(programs) { program in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(program.name).font(.headline)
                                Text(program.path).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Run", systemImage: "play.fill") { onRun(program) }
                            Button(role: .destructive) { onRemove(program) } label: {
                                Label("Remove \(program.name)", systemImage: "trash").labelStyle(.iconOnly)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .frame(minHeight: 120)
                }
            }

            HStack {
                ForEach(Self.tools) { tool in
                    Button(tool.title, systemImage: tool.symbol) { onRunTool(tool.program) }
                }
                Spacer()
                Button("Stop All Programs", systemImage: "stop.circle", role: .destructive, action: onStopAll)
            }
        }
        .padding()
    }
}
