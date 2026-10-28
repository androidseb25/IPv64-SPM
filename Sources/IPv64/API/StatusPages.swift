import Foundation

extension IPv64 {
    /// Public status pages.
    public var statusPages: StatusPages { StatusPages(client: self) }

    /// Endpoints of the *Statusseiten* area.
    public struct StatusPages: Sendable {
        let client: IPv64

        /// All status pages.
        ///
        /// `GET /status-pages`
        public func list() async throws -> [StatusPage] {
            try await client.send(Request(.get, "/status-pages"))
        }

        /// Creates a status page. Without `slug` a random address is assigned.
        ///
        /// `POST /status-pages`
        public func create(_ input: StatusPageInput = StatusPageInput()) async throws -> StatusPage {
            try await client.send(Request(.post, "/status-pages", body: .json(input)))
        }

        /// A single status page.
        ///
        /// `GET /status-pages/{id}`
        public func get(_ id: Int) async throws -> StatusPage {
            try await client.send(Request(.get, "/status-pages/\(id)"))
        }

        /// Changes a status page. Only non-`nil` fields are changed.
        ///
        /// `PATCH /status-pages/{id}`
        public func update(_ id: Int, _ input: StatusPageInput) async throws -> StatusPage {
            try await client.send(Request(.patch, "/status-pages/\(id)", body: .json(input)))
        }

        /// Deletes a status page.
        ///
        /// `DELETE /status-pages/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/status-pages/\(id)"))
        }
    }
}
