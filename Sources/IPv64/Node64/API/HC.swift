import Foundation

extension Node64.HC {
    /// State changes of all checks, newest first.
    ///
    /// Page with `before`: pass the `id` of the last event of the previous page.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of events.
    ///   - before: Only events with a smaller ID (older).
    ///
    /// `GET /events`
    public func events(limit: Int? = nil, before: Int? = nil) async throws -> [Node64.CheckEvent] {
        try await client.send(Request(.get, "/events", query: [
            QueryItem("limit", limit),
            QueryItem("before", before),
        ]))
    }

    /// Outages of all checks.
    ///
    /// - Parameter limit: Maximum number of incidents (server default 50, at most 1000).
    ///
    /// `GET /incidents`
    public func incidents(limit: Int? = nil) async throws -> [Node64.CheckIncident] {
        try await client.send(Request(.get, "/incidents", query: [QueryItem("limit", limit)]))
    }

    /// Sends a heartbeat to a push check, without authentication.
    ///
    /// Without `payload` this is a `GET`; with `payload` it is a `POST` whose body (up to
    /// 4 KB, JSON or `text/plain`) is stored as `details.payload`. The answer is identical for
    /// unknown tokens. Minimum interval 1 s, at most 60 per minute (otherwise `429` with an empty
    /// body). Answers `503` when the push could be neither measured here nor forwarded
    /// (no connection to ipv64). The push also works for checks other nodes measure.
    ///
    /// - Parameters:
    ///   - token: Token of the push check.
    ///   - status: `down` marks the heartbeat as failed; any other value counts as `up`.
    ///   - message: Message, at most 200 characters.
    ///   - payload: Optional body (at most 4 KB); switches the request to `POST`.
    ///   - contentType: Content type of `payload`, `application/json` or `text/plain`.
    ///
    /// `GET /push/{token}`, `POST /push/{token}`
    @discardableResult
    public func push(
        _ token: String,
        status: Node64.PushStatus? = nil,
        message: String? = nil,
        payload: Data? = nil,
        contentType: String = "application/json"
    ) async throws -> Node64.PushResult {
        let query = [QueryItem("status", status), QueryItem("msg", message)]
        if let payload {
            return try await client.send(Request(
                .post, "/push/\(token)", query: query,
                body: .raw(payload, contentType: contentType), authorization: .none
            ))
        }
        return try await client.send(Request(.get, "/push/\(token)", query: query, authorization: .none))
    }
}
