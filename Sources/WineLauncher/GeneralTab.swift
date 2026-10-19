import SwiftUI
import WineLauncherCore

struct GeneralTab: View {
    let windowsVersion: WindowsVersion
    let graphicsBackend: GraphicsBackend
    let onWindowsVersionChange: (WindowsVersion) -> Void
    let onGraphicsBackendChange: (GraphicsBackend) -> Void

    var body: some View {
        Form {
            WindowsVersionPicker(
                selection: Binding(get: { windowsVersion }, set: { onWindowsVersionChange($0) }))
            GraphicsBackendPicker(
                selection: Binding(get: { graphicsBackend }, set: { onGraphicsBackendChange($0) }))
            Text("Changing the Windows version or the graphics backend modifies the bottle's Wine prefix and can take a moment.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
