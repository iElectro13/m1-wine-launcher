import Foundation
import Testing
@testable import WineLauncherCore

struct FileBottleStoreTests {
    private func makeStore() -> (store: FileBottleStore, root: URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("bottles-\(UUID().uuidString)")
        return (FileBottleStore(root: root), root)
    }

    @Test func createBuildsBottleWithDefaultsAndPrefixDirectory() throws {
        let (store, _) = makeStore()

        let bottle = try store.create(name: "Steam")

        #expect(bottle.name == "Steam")
        #expect(bottle.windowsVersion == .win10)
        #expect(bottle.graphicsBackend == .wineDefault)
        #expect(bottle.environment.isEmpty)
        #expect(bottle.dllOverrides.isEmpty)
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: store.prefixURL(for: bottle.id).path, isDirectory: &isDirectory)
        #expect(exists && isDirectory.boolValue)
    }

    @Test func createRejectsBlankName() {
        let (store, _) = makeStore()

        #expect(throws: BottleStoreError.invalidName) {
            try store.create(name: "   ")
        }
    }

    @Test func listReturnsBottlesSortedByName() throws {
        let (store, _) = makeStore()
        _ = try store.create(name: "Zeta")
        _ = try store.create(name: "Alpha")

        let names = try store.list().map(\.name)

        #expect(names == ["Alpha", "Zeta"])
    }

    @Test func listOnMissingRootIsEmpty() throws {
        let (store, _) = makeStore()

        #expect(try store.list().isEmpty)
    }

    @Test func savePersistsChanges() throws {
        let (store, _) = makeStore()
        var bottle = try store.create(name: "Games")
        bottle.windowsVersion = .win11
        bottle.graphicsBackend = .dxvk
        bottle.environment["WINEESYNC"] = "1"
        bottle.dllOverrides["d3d11"] = .native

        try store.save(bottle)

        #expect(try store.load(id: bottle.id) == bottle)
    }

    @Test func deleteRemovesBottleFromDisk() throws {
        let (store, _) = makeStore()
        let bottle = try store.create(name: "Temp")

        try store.delete(id: bottle.id)

        #expect(throws: BottleStoreError.notFound(bottle.id)) {
            try store.load(id: bottle.id)
        }
        #expect(!FileManager.default.fileExists(atPath: store.directory(for: bottle.id).path))
    }

    @Test func loadUnknownIdThrowsNotFound() {
        let (store, _) = makeStore()
        let id = UUID()

        #expect(throws: BottleStoreError.notFound(id)) {
            try store.load(id: id)
        }
    }
}
