import SwiftUI
import WineLauncherCore

struct DiagnosticsSheet: View {
    let items: [DiagnosticItem]
    let isRunning: Bool
    let onRerun: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostics").font(.title2.bold())

            if isRunning && items.isEmpty {
                ProgressView("Checking…").frame(maxWidth: .infinity)
            } else {
                List(items, id: \.name) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: item.status.symbolName)
                            .foregroundStyle(item.status.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.headline)
                            Text(item.detail)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack {
                Button("Run Again", action: onRerun).disabled(isRunning)
                Spacer()
                Button("Done", action: onClose).keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 480, height: 340)
    }
}
