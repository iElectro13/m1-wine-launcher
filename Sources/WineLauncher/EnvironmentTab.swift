import SwiftUI

struct EnvironmentTab: View {
    let environment: [String: String]
    let onChange: ([String: String]) -> Void

    @State private var newName = ""
    @State private var newValue = ""

    private struct QuickToggle: Identifiable {
        let title: String
        let name: String
        let value: String
        var id: String { name }
    }

    private static let quickToggles = [
        QuickToggle(title: "ESync", name: "WINEESYNC", value: "1"),
        QuickToggle(title: "MSync", name: "WINEMSYNC", value: "1"),
        QuickToggle(title: "DXVK HUD (frame rate)", name: "DXVK_HUD", value: "fps"),
        QuickToggle(title: "Wine debug output (loaded DLLs)", name: "WINEDEBUG", value: "+loaddll"),
    ]

    private var variables: [Variable] {
        environment.sorted { $0.key < $1.key }.map { Variable(name: $0.key, value: $0.value) }
    }

    private var canAdd: Bool {
        let name = newName.trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && !name.contains("=")
    }

    var body: some View {
        Form {
            Section("Quick settings") {
                ForEach(Self.quickToggles) { quickToggle in
                    Toggle(
                        quickToggle.title,
                        isOn: Binding(
                            get: { environment[quickToggle.name] == quickToggle.value },
                            set: { set(quickToggle.name, $0 ? quickToggle.value : nil) }))
                }
            }

            Section("Variables") {
                ForEach(variables) { variable in
                    EnvironmentVariableRow(
                        name: variable.name, value: variable.value,
                        onCommit: { set(variable.name, $0) },
                        onRemove: { set(variable.name, nil) })
                }
                HStack {
                    TextField("NAME", text: $newName)
                    TextField("value", text: $newValue)
                    Button("Add", action: add).disabled(!canAdd)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func set(_ name: String, _ value: String?) {
        var updated = environment
        updated[name] = value
        onChange(updated)
    }

    private func add() {
        set(newName.trimmingCharacters(in: .whitespaces), newValue)
        newName = ""
        newValue = ""
    }
}

private struct Variable: Identifiable {
    let name: String
    let value: String
    // Includes the value so a row restarts its editing draft when the value changes elsewhere.
    var id: String { "\(name)=\(value)" }
}
