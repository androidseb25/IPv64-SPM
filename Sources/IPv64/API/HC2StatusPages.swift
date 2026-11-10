import Foundation

extension IPv64.HC2 {
    /// Endpoints for Healthchecks 2.0 status pages and their notices.
    public struct StatusPages: Sendable {
        let client: IPv64

        /// All status pages (without groups).
        ///
        /// `GET /hc2/status-pages`
        public func list() async throws -> [HC2StatusPage] {
            try await client.send(Request(.get, "/hc2/status-pages"))
        }

        /// Creates a status page. `title` is required.
        ///
        /// `POST /hc2/status-pages`
        public func create(_ input: HC2StatusPageInput) async throws -> HC2StatusPage {
            try await client.send(Request(.post, "/hc2/status-pages", body: .json(input)))
        }

        /// A single status page including its groups.
        ///
        /// `GET /hc2/status-pages/{id}`
        public func get(_ id: Int) async throws -> HC2StatusPage {
            try await client.send(Request(.get, "/hc2/status-pages/\(id)"))
        }

        /// Changes a status page. Only non-`nil` fields are changed; `groups` replaces all groups.
        ///
        /// `PATCH /hc2/status-pages/{id}`
        public func update(_ id: Int, _ input: HC2StatusPageInput) async throws -> HC2StatusPage {
            try await client.send(Request(.patch, "/hc2/status-pages/\(id)", body: .json(input)))
        }

        /// Deletes a status page together with its notices; the address becomes free.
        ///
        /// `DELETE /hc2/status-pages/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/hc2/status-pages/\(id)"))
        }

        /// Notices of a status page.
        ///
        /// - Parameter page: Status page ID.
        ///
        /// `GET /hc2/status-pages/{id}/notices`
        public func notices(_ page: Int) async throws -> [HC2StatusNotice] {
            try await client.send(Request(.get, "/hc2/status-pages/\(page)/notices"))
        }

        /// Creates a notice on a status page. `title` is required.
        ///
        /// - Parameter page: Status page ID.
        ///
        /// `POST /hc2/status-pages/{id}/notices`
        public func createNotice(_ page: Int, _ input: HC2StatusNoticeInput) async throws -> HC2StatusNotice {
            try await client.send(Request(.post, "/hc2/status-pages/\(page)/notices", body: .json(input)))
        }

        /// Changes a notice. Only non-`nil` fields are changed.
        ///
        /// - Parameters:
        ///   - page: Status page ID.
        ///   - notice: Notice ID.
        ///
        /// `PATCH /hc2/status-pages/{id}/notices/{nid}`
        public func updateNotice(_ page: Int, notice: Int, _ input: HC2StatusNoticeInput) async throws -> HC2StatusNotice {
            try await client.send(Request(.patch, "/hc2/status-pages/\(page)/notices/\(notice)", body: .json(input)))
        }

        /// Deletes a notice.
        ///
        /// - Parameters:
        ///   - page: Status page ID.
        ///   - notice: Notice ID.
        ///
        /// `DELETE /hc2/status-pages/{id}/notices/{nid}`
        public func deleteNotice(_ page: Int, notice: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/hc2/status-pages/\(page)/notices/\(notice)"))
        }
    }
}
