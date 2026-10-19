import SwiftUI
import WineLauncherCore

struct DLLOverridesTab: View {
    let overrides: [String: DLLOverride]
    let onChange: ([String: DLLOverride]) -> Void

    @State private var newName = ""
    @State private var newMode = DLLOverride.nativeThenBuiltin

    private var trimmedName: String {
        newName.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        Form {
            Section("Overrides") {
                ForEach(overrides.keys.sorted(), id: \.self) { dll in
                    HStack {
                        Text(dll).font(.system(.body, design: .monospaced))
                        Spacer()
                        Picker(dll, selection: Binding(
                            get: { overrides[dll] ?? .builtin }, set: { set(dll, $0) })
                        ) {
                            modes
                        }
                        .labelsHidden()
                        .fixedSize()
                        Button(role: .destructive) { set(dll, nil) } label: {
                            Label("Remove \(dll)", systemImage: "trash").labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    TextField("DLL name, e.g. d3d11", text: $newName)
                    Picker("Mode", selection: $newMode) { modes }
                        .labelsHidden()
                        .fixedSize()
                    Button("Add") {
                        set(trimmedName, newMode)
                        newName = ""
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            Text("Overrides required by the graphics backend are applied automatically and are not listed here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var modes: some View {
        ForEach(DLLOverride.allCases, id: \.self) { mode in
            Text(mode.title).tag(mode)
        }
    }

    private func set(_ dll: String, _ mode: DLLOverride?) {
        var updated = overrides
        updated[dll] = mode
        onChange(updated)
    }
}
