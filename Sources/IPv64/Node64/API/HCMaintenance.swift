import Foundation

extension Node64.HC {
    /// Maintenance windows in which checks stay silent.
    public var maintenance: Maintenance { Maintenance(client: client) }

    /// Endpoints below `/maintenance`.
    public struct Maintenance: Sendable { let client: Node64 }
}

extension Node64.HC.Maintenance {
    /// All maintenance windows.
    ///
    /// `GET /maintenance`
    public func list() async throws -> [Node64.Maintenance] {
        try await client.send(Request(.get, "/maintenance"))
    }

    /// Creates a maintenance window. The spec documents no response body.
    ///
    /// `POST /maintenance`
    @discardableResult
    public func create(_ window: Node64.MaintenanceInput) async throws -> JSONValue {
        try await client.sendJSON(Request(.post, "/maintenance", body: .json(window)))
    }

    /// Replaces a maintenance window **completely**: send all fields, as when creating.
    ///
    /// Optional fields you leave `nil` are not kept but fall back to the server defaults (for example
    /// no `tokens` = all checks, `active` on). Start from the values of ``list()`` to change a
    /// single field. Also works for windows of other nodes and from the portal. The spec documents
    /// no response body.
    ///
    /// `PUT /maintenance/{id}`
    @discardableResult
    public func update(_ id: Int, _ window: Node64.MaintenanceInput) async throws -> JSONValue {
        try await client.sendJSON(Request(.put, "/maintenance/\(id)", body: .json(window)))
    }

    /// Deletes a maintenance window everywhere, also windows of other nodes. Answers `204` even
    /// for unknown IDs.
    ///
    /// `DELETE /maintenance/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/maintenance/\(id)"))
    }
}
