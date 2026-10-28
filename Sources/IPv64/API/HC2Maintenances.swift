import Foundation

extension IPv64.HC2 {
    /// Endpoints for maintenance windows.
    public struct Maintenances: Sendable {
        let client: IPv64

        /// Lists maintenance windows.
        ///
        /// `GET /hc2/maintenance`
        public func list() async throws -> [HC2Maintenance] {
            try await client.send(Request(.get, "/hc2/maintenance"))
        }

        /// Creates a maintenance window. `name`, `startAt` and `endAt` are required.
        ///
        /// `POST /hc2/maintenance`
        public func create(_ maintenance: HC2MaintenanceInput) async throws -> HC2Maintenance {
            try await client.send(Request(.post, "/hc2/maintenance", body: .json(maintenance)))
        }

        /// A maintenance window.
        ///
        /// `GET /hc2/maintenance/{id}`
        public func get(_ id: Int) async throws -> HC2Maintenance {
            try await client.send(Request(.get, "/hc2/maintenance/\(id)"))
        }

        /// Updates a maintenance window.
        ///
        /// `PATCH /hc2/maintenance/{id}`
        public func update(_ id: Int, _ maintenance: HC2MaintenanceInput) async throws -> HC2Maintenance {
            try await client.send(Request(.patch, "/hc2/maintenance/\(id)", body: .json(maintenance)))
        }

        /// Deletes a maintenance window.
        ///
        /// `DELETE /hc2/maintenance/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/hc2/maintenance/\(id)"))
        }
    }
}
