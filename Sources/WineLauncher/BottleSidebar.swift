import SwiftUI
import WineLauncherCore

struct BottleSidebar: View {
    let bottles: [Bottle]
    @Binding var selection: Bottle.ID?
    let onAdd: () -> Void
    let onDelete: (Bottle) -> Void

    var body: some View {
        List(bottles, selection: $selection) { bottle in
            Label(bottle.name, systemImage: "shippingbox")
                .contextMenu {
                    Button("Delete…", role: .destructive) { onDelete(bottle) }
                }
        }
        .overlay {
            if bottles.isEmpty {
                ContentUnavailableView(
                    "No Bottles", systemImage: "shippingbox",
                    description: Text("Create a bottle to install Windows programs."))
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onAdd) {
                Label("New Bottle", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .padding(10)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 240)
    }
}
