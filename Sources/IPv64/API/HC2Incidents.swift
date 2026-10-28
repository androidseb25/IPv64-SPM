import Foundation

extension IPv64.HC2 {
    /// Endpoints for incidents (periods of failure).
    public struct Incidents: Sendable {
        let client: IPv64

        /// Incidents of the account.
        ///
        /// - Parameters:
        ///   - limit: At most 1000.
        ///   - open: `true` = only open incidents (sent as `open=true`).
        ///   - since: Only incidents from this point in time.
        ///
        /// `GET /hc2/incidents`
        public func list(
            limit: Int? = nil,
            open: Bool? = nil,
            since: Date? = nil
        ) async throws -> [HC2Incident] {
            try await client.send(Request(.get, "/hc2/incidents", query: [
                QueryItem("limit", limit),
                QueryItem("open", open),
                QueryItem("since", since),
            ]))
        }

        /// Incidents of one check.
        ///
        /// - Parameters:
        ///   - check: Check token.
        ///   - limit: At most 500.
        ///
        /// `GET /hc2/checks/{token}/incidents`
        public func list(check token: String, limit: Int? = nil) async throws -> [HC2Incident] {
            try await client.send(Request(.get, "/hc2/checks/\(token)/incidents", query: [QueryItem("limit", limit)]))
        }
    }
}
