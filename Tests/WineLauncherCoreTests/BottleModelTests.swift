import Foundation
import Testing
@testable import WineLauncherCore

struct BottleModelTests {
    @Test func bottlesSavedBeforePinnedProgramsExistedStillDecode() throws {
        let legacy = """
            {"id":"\(UUID().uuidString)","name":"Old","windowsVersion":"win10",
             "graphicsBackend":"wineDefault","environment":{},"dllOverrides":{}}
            """

        let bottle = try JSONDecoder().decode(Bottle.self, from: Data(legacy.utf8))

        #expect(bottle.name == "Old")
        #expect(bottle.pinnedPrograms.isEmpty)
    }

    @Test func pinnedProgramsRoundTrip() throws {
        let bottle = Bottle(
            name: "B",
            pinnedPrograms: [PinnedProgram(name: "Steam", path: "C:\\steam.exe", arguments: ["-x"])])

        let decoded = try JSONDecoder().decode(Bottle.self, from: JSONEncoder().encode(bottle))

        #expect(decoded == bottle)
    }
}
