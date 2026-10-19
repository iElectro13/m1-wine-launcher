import SwiftUI

struct RuntimeSetupView: View {
    let state: RuntimeState
    let onInstall: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Set up Wine").font(.largeTitle.bold())
            content
            rosettaHint
        }
        .padding(40)
        .frame(maxWidth: 520, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .checking, .ready:
            ProgressView("Looking for an installed Wine…")
        case .notInstalled:
            explanation
            Button("Download Wine", action: onInstall)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        case .installing(let progress):
            explanation
            if progress < 1 {
                ProgressView(value: progress) {
                    Text("Downloading Wine…")
                } currentValueLabel: {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                }
            } else {
                ProgressView("Unpacking Wine…")
            }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .textSelection(.enabled)
            Button("Try Again", action: onInstall)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var explanation: some View {
        Text(
            "Wine is downloaded once from Gcenx/macOS_Wine_builds (about 190 MB) and shared by all your bottles."
        )
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    }

    private var rosettaHint: some View {
        VStack(spacing: 4) {
            Text("This Wine build is Intel-only, so Apple Silicon Macs need Rosetta 2:")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(verbatim: "softwareupdate --install-rosetta --agree-to-license")
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(.top, 8)
    }
}
