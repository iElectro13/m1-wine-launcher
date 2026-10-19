import SwiftUI
import WineLauncherCore

struct WindowsVersionPicker: View {
    @Binding var selection: WindowsVersion

    var body: some View {
        Picker("Windows version", selection: $selection) {
            ForEach(WindowsVersion.allCases, id: \.self) { version in
                Text(version.title).tag(version)
            }
        }
    }
}
