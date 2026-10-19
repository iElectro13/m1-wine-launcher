import SwiftUI
import WineLauncherCore

struct RootView: View {
    @Bindable var model: AppModel

    @State private var showingNewBottle = false
    @State private var showingDiagnostics = false
    @State private var bottlePendingDeletion: Bottle?

    var body: some View {
        Group {
            if case .ready = model.runtimeState {
                library
            } else {
                RuntimeSetupView(state: model.runtimeState, onInstall: model.installRuntime)
            }
        }
        .frame(minWidth: 860, minHeight: 540)
        .overlay(alignment: .bottom) {
            if let message = model.busyMessage { BusyBanner(message: message) }
        }
        .task { await model.bootstrap() }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } })
        ) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var library: some View {
        NavigationSplitView {
            BottleSidebar(
                bottles: model.bottles,
                selection: $model.selectedBottleID,
                onAdd: { showingNewBottle = true },
                onDelete: { bottlePendingDeletion = $0 })
        } detail: {
            if let bottle = model.selectedBottle {
                BottleDetailView(model: model, bottle: bottle)
            } else {
                ContentUnavailableView("No Bottle Selected", systemImage: "shippingbox")
            }
        }
        .disabled(model.isBusy)
        .toolbar {
            ToolbarItem {
                Button("Diagnostics", systemImage: "stethoscope") { showingDiagnostics = true }
            }
        }
        .sheet(isPresented: $showingNewBottle) {
            NewBottleSheet(
                onCreate: { name, version, backend in
                    showingNewBottle = false
                    model.createBottle(name: name, windowsVersion: version, backend: backend)
                },
                onCancel: { showingNewBottle = false })
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsSheet(
                items: model.diagnostics,
                isRunning: model.isRunningDiagnostics,
                onRerun: { Task { await model.runDiagnostics() } },
                onClose: { showingDiagnostics = false }
            )
            .task { await model.runDiagnostics() }
        }
        .confirmationDialog(
            "Delete this bottle?",
            isPresented: Binding(
                get: { bottlePendingDeletion != nil },
                set: { if !$0 { bottlePendingDeletion = nil } }),
            titleVisibility: .visible,
            presenting: bottlePendingDeletion
        ) { bottle in
            Button("Delete \(bottle.name)", role: .destructive) { model.deleteBottle(bottle) }
        } message: { _ in
            Text("Its Windows files and installed programs are removed permanently.")
        }
    }
}
