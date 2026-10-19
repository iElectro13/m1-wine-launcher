import SwiftUI
import WineLauncherCore

struct NewBottleSheet: View {
    let onCreate: (String, WindowsVersion, GraphicsBackend) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var windowsVersion = WindowsVersion.win10
    @State private var backend = GraphicsBackend.wineDefault

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Name", text: $name)
                WindowsVersionPicker(selection: $windowsVersion)
                GraphicsBackendPicker(selection: $backend)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Create") { onCreate(trimmedName, windowsVersion, backend) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmedName.isEmpty)
            }
            .padding([.horizontal, .bottom])
        }
        .frame(width: 420)
    }
}
