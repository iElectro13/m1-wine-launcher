import SwiftUI
import WineLauncherCore

struct GraphicsBackendPicker: View {
    @Binding var selection: GraphicsBackend

    var body: some View {
        Picker("Graphics backend", selection: $selection) {
            ForEach(GraphicsBackend.allCases, id: \.self) { backend in
                Text(backend.isAvailable ? backend.title : "\(backend.title) (Not available yet)")
                    .tag(backend)
                    .disabled(!backend.isAvailable)
            }
        }
    }
}
