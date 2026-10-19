import SwiftUI

@main
struct WineLauncherApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
        .defaultSize(width: 980, height: 640)
    }
}
