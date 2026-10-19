import SwiftUI

struct EnvironmentVariableRow: View {
    let name: String
    let onCommit: (String) -> Void
    let onRemove: () -> Void

    @State private var draft: String

    init(
        name: String, value: String, onCommit: @escaping (String) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.name = name
        self.onCommit = onCommit
        self.onRemove = onRemove
        _draft = State(initialValue: value)
    }

    var body: some View {
        HStack {
            Text(name).font(.system(.body, design: .monospaced))
            Spacer()
            TextField("value", text: $draft)
                .labelsHidden()
                .frame(maxWidth: 220)
                .onSubmit { onCommit(draft) }
            Button(role: .destructive, action: onRemove) {
                Label("Remove \(name)", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
    }
}
