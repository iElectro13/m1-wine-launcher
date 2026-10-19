import Foundation
import Testing
@testable import WineLauncherCore

struct WineCommandBuilderTests {
    private let wine = URL(fileURLWithPath: "/opt/wine/bin/wine")
    private let prefix = URL(fileURLWithPath: "/bottles/abc/prefix")

    private func makeBuilder() -> WineCommandBuilder {
        WineCommandBuilder(runtime: WineRuntime(wineExecutable: wine))
    }

    @Test func launchRunsProgramWithArgumentsThroughWine() {
        let bottle = Bottle(name: "Games")

        let command = makeBuilder().launch(
            program: "C:\\Steam\\steam.exe", arguments: ["-silent"], in: bottle, prefix: prefix)

        #expect(command.executable == wine)
        #expect(command.arguments == ["C:\\Steam\\steam.exe", "-silent"])
    }

    @Test func launchPointsWinePrefixAtTheBottlePrefix() {
        let command = makeBuilder().launch(program: "a.exe", in: Bottle(name: "Games"), prefix: prefix)

        #expect(command.environment["WINEPREFIX"] == prefix.path)
    }

    @Test func launchSilencesWineDebugByDefaultButBottleCanOverrideIt() {
        let quiet = makeBuilder().launch(program: "a.exe", in: Bottle(name: "Q"), prefix: prefix)
        let verbose = makeBuilder().launch(
            program: "a.exe",
            in: Bottle(name: "V", environment: ["WINEDEBUG": "+loaddll"]),
            prefix: prefix)

        #expect(quiet.environment["WINEDEBUG"] == "-all")
        #expect(verbose.environment["WINEDEBUG"] == "+loaddll")
    }

    @Test func bottleEnvironmentCannotRedirectThePrefix() {
        let bottle = Bottle(name: "Games", environment: ["WINEPREFIX": "/elsewhere", "WINEESYNC": "1"])

        let command = makeBuilder().launch(program: "a.exe", in: bottle, prefix: prefix)

        #expect(command.environment["WINEPREFIX"] == prefix.path)
        #expect(command.environment["WINEESYNC"] == "1")
    }

    @Test func noOverridesMeansNoDllOverridesVariable() {
        let command = makeBuilder().launch(program: "a.exe", in: Bottle(name: "Games"), prefix: prefix)

        #expect(command.environment["WINEDLLOVERRIDES"] == nil)
    }

    @Test func dllOverridesAreSortedAndEncodedInWineSyntax() {
        let bottle = Bottle(
            name: "Games",
            dllOverrides: [
                "mscoree": .disabled,
                "dxgi": .builtin,
                "d3d11": .native,
                "winhttp": .nativeThenBuiltin,
                "ole32": .builtinThenNative,
            ])

        let command = makeBuilder().launch(program: "a.exe", in: bottle, prefix: prefix)

        #expect(
            command.environment["WINEDLLOVERRIDES"]
                == "d3d11=n;dxgi=b;mscoree=;ole32=b,n;winhttp=n,b")
    }

    @Test func dxvkBackendAddsItsOverrides() {
        let bottle = Bottle(name: "Games", graphicsBackend: .dxvk)

        let command = makeBuilder().launch(program: "a.exe", in: bottle, prefix: prefix)

        #expect(
            command.environment["WINEDLLOVERRIDES"]
                == "d3d10core=n,b;d3d11=n,b;d3d9=n,b;dxgi=n,b")
    }

    @Test func explicitBottleOverrideWinsOverBackendOverride() {
        let bottle = Bottle(name: "Games", graphicsBackend: .dxvk, dllOverrides: ["dxgi": .builtin])

        let command = makeBuilder().launch(program: "a.exe", in: bottle, prefix: prefix)

        #expect(
            command.environment["WINEDLLOVERRIDES"]
                == "d3d10core=n,b;d3d11=n,b;d3d9=n,b;dxgi=b")
    }

    @Test func initializePrefixRunsWineboot() {
        let command = makeBuilder().initializePrefix(for: Bottle(name: "Games"), prefix: prefix)

        #expect(command.executable == wine)
        #expect(command.arguments == ["wineboot", "--init"])
        #expect(command.environment["WINEPREFIX"] == prefix.path)
    }

    @Test func setWindowsVersionUsesWinecfg() {
        let bottle = Bottle(name: "Games", windowsVersion: .win11)

        let command = makeBuilder().setWindowsVersion(for: bottle, prefix: prefix)

        #expect(command.arguments == ["winecfg", "-v", "win11"])
        #expect(command.environment["WINEPREFIX"] == prefix.path)
    }
}
