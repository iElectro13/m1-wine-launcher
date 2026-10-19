import SwiftUI
import WineLauncherCore

extension WindowsVersion {
    var title: String {
        switch self {
        case .win7: "Windows 7"
        case .win10: "Windows 10"
        case .win11: "Windows 11"
        }
    }
}

extension GraphicsBackend {
    var title: String {
        switch self {
        case .wineDefault: "Wine default (OpenGL)"
        case .dxvk: "DXVK (Vulkan via MoltenVK)"
        case .dxmt: "DXMT (Metal)"
        case .d3dMetal: "D3DMetal"
        }
    }

    /// Backends the core cannot install yet.
    var isAvailable: Bool {
        switch self {
        case .wineDefault, .dxvk: true
        case .dxmt, .d3dMetal: false
        }
    }
}

extension DLLOverride {
    var title: String {
        switch self {
        case .native: "Native"
        case .builtin: "Built-in"
        case .nativeThenBuiltin: "Native, then built-in"
        case .builtinThenNative: "Built-in, then native"
        case .disabled: "Disabled"
        }
    }
}

extension DiagnosticStatus {
    var symbolName: String {
        switch self {
        case .ok: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .failure: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .ok: .green
        case .warning: .orange
        case .failure: .red
        }
    }
}
