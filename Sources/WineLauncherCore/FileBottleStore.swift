import Foundation

/// Stores each bottle under `<root>/<id>/` with its metadata in `bottle.json`
/// and the Wine prefix in `prefix/`.
public struct FileBottleStore: BottleStore {
    private let root: URL

    public init(root: URL) {
        self.root = root
    }

    public func directory(for id: UUID) -> URL {
        root.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    public func prefixURL(for id: UUID) -> URL {
        directory(for: id).appendingPathComponent("prefix", isDirectory: true)
    }

    private func metadataURL(for id: UUID) -> URL {
        directory(for: id).appendingPathComponent("bottle.json")
    }

    public func create(name: String) throws -> Bottle {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw BottleStoreError.invalidName }

        let bottle = Bottle(name: trimmed)
        try FileManager.default.createDirectory(
            at: prefixURL(for: bottle.id), withIntermediateDirectories: true)
        try save(bottle)
        return bottle
    }

    public func list() throws -> [Bottle] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        let entries = try FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil)
        return entries
            .compactMap { UUID(uuidString: $0.lastPathComponent) }
            .compactMap { try? load(id: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func load(id: UUID) throws -> Bottle {
        guard let data = try? Data(contentsOf: metadataURL(for: id)) else {
            throw BottleStoreError.notFound(id)
        }
        return try JSONDecoder().decode(Bottle.self, from: data)
    }

    public func save(_ bottle: Bottle) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(
            at: directory(for: bottle.id), withIntermediateDirectories: true)
        try encoder.encode(bottle).write(to: metadataURL(for: bottle.id), options: .atomic)
    }

    public func delete(id: UUID) throws {
        guard FileManager.default.fileExists(atPath: directory(for: id).path) else {
            throw BottleStoreError.notFound(id)
        }
        try FileManager.default.removeItem(at: directory(for: id))
    }
}
