import Foundation

public enum BottleStoreError: Error, Equatable {
    case invalidName
    case notFound(UUID)
}

/// Port: persistence of bottles, independent of where they are stored.
public protocol BottleStore: Sendable {
    func create(name: String) throws -> Bottle
    func list() throws -> [Bottle]
    func load(id: UUID) throws -> Bottle
    func save(_ bottle: Bottle) throws
    func delete(id: UUID) throws
}
