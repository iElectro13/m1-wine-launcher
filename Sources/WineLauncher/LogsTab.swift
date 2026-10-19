import SwiftUI

struct LogsTab: View {
    let loadLogFiles: () -> [URL]

    @State private var files: [URL] = []
    @State private var selection: URL?
    @State private var text = ""
    @State private var generation = 0

    private struct TextKey: Equatable {
        let file: URL?
        let generation: Int
    }

    var body: some View {
        HStack(spacing: 0) {
            List(files, id: \.self, selection: $selection) { file in
                Text(Self.title(for: file))
            }
            .overlay {
                if files.isEmpty {
                    ContentUnavailableView("No Logs", systemImage: "doc.text")
                }
            }
            .frame(width: 220)

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Refresh", systemImage: "arrow.clockwise") { generation += 1 }
                }
                .padding(8)
                Divider()
                ScrollView([.vertical, .horizontal]) {
                    Text(text)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .task(id: generation) {
            files = loadLogFiles()
            if !files.contains(where: { $0 == selection }) { selection = files.first }
        }
        .task(id: TextKey(file: selection, generation: generation)) {
            text = await Self.read(selection)
        }
    }

    /// Log names start with `yyyyMMdd-HHmmss`; anything else is shown as is.
    private static func title(for file: URL) -> String {
        let name = file.deletingPathExtension().lastPathComponent
        let parts = name.split(separator: "-")
        guard parts.count >= 2, parts[0].count == 8, parts[1].count == 6 else { return name }
        let date = Array(parts[0])
        let time = Array(parts[1])
        return "\(String(date[0..<4]))-\(String(date[4..<6]))-\(String(date[6..<8])) "
            + "\(String(time[0..<2])):\(String(time[2..<4])):\(String(time[4..<6]))"
    }

    /// Wine can be very chatty, so only the end of a huge log is shown.
    private static func read(_ file: URL?) async -> String {
        guard let file else { return "" }
        return await Task.detached {
            guard let data = try? Data(contentsOf: file) else { return "Could not read the log file." }
            let limit = 512 * 1024
            guard data.count > limit else { return String(decoding: data, as: UTF8.self) }
            return "… (earlier output omitted)\n" + String(decoding: data.suffix(limit), as: UTF8.self)
        }.value
    }
}
