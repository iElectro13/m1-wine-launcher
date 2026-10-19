import AppKit
import UniformTypeIdentifiers

enum ExecutablePanel {
    /// Asks the user for a Windows executable; returns nil when they cancel.
    @MainActor
    static func choose() -> URL? {
        let panel = NSOpenPanel()
        panel.message = "Choose a Windows program to run"
        panel.allowedContentTypes = [UTType(filenameExtension: "exe")].compactMap { $0 }
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }
}
