import Foundation

extension Node64.HC {
    /// Checks of the node: definition, control, measurements and statistics.
    public var checks: Checks { Checks(client: client) }

    /// Endpoints below `/checks`.
    public struct Checks: Sendable { let client: Node64 }
}

extension Node64.HC.Checks {
    /// All checks, including those of other nodes of the account.
    ///
    /// - Parameters:
    ///   - type: Only checks of this type.
    ///   - state: Only checks in this state.
    ///   - tag: Only checks with this tag.
    ///   - query: Search text (query parameter `q`).
    ///
    /// `GET /checks`
    public func list(
        type: Node64.CheckType? = nil,
        state: Node64.CheckStateKind? = nil,
        tag: String? = nil,
        query: String? = nil
    ) async throws -> [Node64.Check] {
        try await client.send(Request(.get, "/checks", query: [
            QueryItem("type", type),
            QueryItem("state", state),
            QueryItem("tag", tag),
            QueryItem("q", query),
        ]))
    }

    /// Available check types (`http`, `keyword`, `icmp`, `tcp`, `port`, `cert`, `push`, `docker`, …).
    ///
    /// The spec documents no response schema, only "list of types". A JSON array of strings, or of
    /// objects with a `type`, `name` or `id` string, is mapped to ``Node64/CheckType`` values; an object
    /// with such an array under `types` is accepted as well. Any other shape throws ``Node64Error/decoding(_:body:)``.
    ///
    /// `GET /check-types`
    public func types() async throws -> [Node64.CheckType] {
        let (data, _) = try await client.perform(Request(.get, "/check-types"))
        let value = try client.decode(JSONValue.self, from: data)
        let items: [JSONValue]
        if case .array(let array) = value {
            items = array
        } else if case .array(let array)? = value["types"] {
            items = array
        } else {
            throw Node64Error.decoding(
                DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected a list of check types.")),
                body: data
            )
        }
        return items.compactMap { item in
            let name = item.stringValue ?? item["type"]?.stringValue ?? item["name"]?.stringValue ?? item["id"]?.stringValue
            return name.map(Node64.CheckType.init(rawValue:))
        }
    }

    /// Creates a check. Required: `name`, `type`, `target` (except for push); see ``Node64/CheckInput``.
    ///
    /// With an ipv64 link, `execution` and `nodes` determine the measuring points. The creating
    /// node owns the check. The spec documents no response body; the answer is returned as JSON.
    ///
    /// `POST /checks`
    @discardableResult
    public func create(_ check: Node64.CheckInput) async throws -> JSONValue {
        try await client.sendJSON(Request(.post, "/checks", body: .json(check)))
    }

    /// A single check including its state.
    ///
    /// `GET /checks/{token}`
    public func get(_ token: String) async throws -> Node64.Check {
        try await client.send(Request(.get, "/checks/\(token)"))
    }

    /// Changes a check.
    ///
    /// `name`, `type` and `target` are always applied, so ``Node64/CheckInput`` requires them.
    /// **A `nil` `description` clears the stored description** – send the current one to keep it.
    /// Omitted `params`, `tags`, `channels`, `locations`, `nodes` and all number and switch
    /// fields stay unchanged. Also works for checks of other nodes (`owner: other`); the owner node
    /// and the measuring point of a Docker check stay. The spec documents no response body.
    ///
    /// `PUT /checks/{token}`
    @discardableResult
    public func update(_ token: String, _ check: Node64.CheckInput) async throws -> JSONValue {
        try await client.sendJSON(Request(.put, "/checks/\(token)", body: .json(check)))
    }

    /// Deletes a check with all measurements, on all nodes and at ipv64, even if another node owns it.
    ///
    /// `DELETE /checks/{token}`
    public func delete(_ token: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/checks/\(token)"))
    }

    /// Pauses a check on all nodes, also checks of other nodes.
    ///
    /// `POST /checks/{token}/pause`
    public func pause(_ token: String) async throws -> Node64.Check {
        try await client.send(Request(.post, "/checks/\(token)/pause"))
    }

    /// Resumes a check on all nodes (it is measured immediately), also checks of other nodes.
    ///
    /// `POST /checks/{token}/resume`
    public func resume(_ token: String) async throws -> Node64.Check {
        try await client.send(Request(.post, "/checks/\(token)/resume"))
    }

    /// Measures a check now: on this node if it measures the check, and via ipv64 on the other
    /// measuring nodes. Answers `202` without content.
    ///
    /// Fails with `409` for push checks, for checks only ipv64 measures, and when no measuring
    /// node is reachable.
    ///
    /// `POST /checks/{token}/run`
    public func run(_ token: String) async throws {
        try await client.sendWithoutContent(Request(.post, "/checks/\(token)/run"))
    }

    /// Copies a check. The copy is named "... (copy)", paused, and belongs to this node
    /// (execution `local` for checks of other nodes).
    ///
    /// `POST /checks/{token}/clone`
    public func clone(_ token: String) async throws -> Node64.Check {
        try await client.send(Request(.post, "/checks/\(token)/clone"))
    }

    /// Measurements of a check, newest first.
    ///
    /// Page with `before`: pass the `seq` of the last measurement of the previous page.
    ///
    /// - Parameters:
    ///   - token: Check token.
    ///   - limit: Maximum number of measurements (default 100, at most 5000).
    ///   - before: Cursor: only measurements with a smaller `seq`.
    ///   - from: Start of the time range.
    ///   - to: End of the time range.
    ///
    /// `GET /checks/{token}/measurements`
    public func measurements(
        _ token: String,
        limit: Int? = nil,
        before: Int? = nil,
        from: String? = nil,
        to: String? = nil
    ) async throws -> [Node64.CheckMeasurement] {
        try await client.send(Request(.get, "/checks/\(token)/measurements", query: [
            QueryItem("limit", limit),
            QueryItem("before", before),
            QueryItem("from", from),
            QueryItem("to", to),
        ]))
    }

    /// State changes of a check, newest first.
    ///
    /// Page with `before`: pass the `id` of the last event of the previous page.
    ///
    /// `GET /checks/{token}/events`
    public func events(_ token: String, limit: Int? = nil, before: Int? = nil) async throws -> [Node64.CheckEvent] {
        try await client.send(Request(.get, "/checks/\(token)/events", query: [
            QueryItem("limit", limit),
            QueryItem("before", before),
        ]))
    }

    /// Outages of a check.
    ///
    /// - Parameter limit: Maximum number of incidents (default 50, at most 1000).
    ///
    /// `GET /checks/{token}/incidents`
    public func incidents(_ token: String, limit: Int? = nil) async throws -> [Node64.CheckIncident] {
        try await client.send(Request(.get, "/checks/\(token)/incidents", query: [QueryItem("limit", limit)]))
    }

    /// Availability and latency of a check as a time series.
    ///
    /// - Parameter range: `1h`, `24h` (default), `7d`, `30d` or `1y`.
    ///
    /// `GET /checks/{token}/stats`
    public func stats(_ token: String, range: Node64.CheckStatsRange? = nil) async throws -> Node64.CheckStats {
        try await client.send(Request(.get, "/checks/\(token)/stats", query: [QueryItem("range", range)]))
    }

    /// Latency per measuring point (this node, other nodes, ipv64 locations).
    ///
    /// 1h to 24h return single measurements, 7d and 30d hourly, 1y daily values. `ms == nil`
    /// means down or no measurement; `up` (percent) exists for hourly and daily values only.
    ///
    /// `GET /checks/{token}/chart`
    public func chart(_ token: String, range: Node64.CheckChartRange) async throws -> Node64.CheckChart {
        try await client.send(Request(.get, "/checks/\(token)/chart", query: [QueryItem("range", range)]))
    }

    /// Runs one action for up to 1000 checks.
    ///
    /// - Parameters:
    ///   - action: The action.
    ///   - tokens: Check tokens, 1 to 1000.
    ///   - tag: Tag, required for `tag` and `untag`.
    ///
    /// `POST /checks/bulk`
    public func bulk(
        _ action: Node64.CheckBulkAction,
        tokens: [String],
        tag: String? = nil
    ) async throws -> Node64.CheckBulkResult {
        try await client.send(Request(.post, "/checks/bulk", body: .json(BulkBody(action: action, tokens: tokens, tag: tag))))
    }

    /// Test run by ipv64 before switching a check to `online` or `both`.
    ///
    /// The ipv64 locations measure the definition once (up to about 70 s); nothing is stored. Needs
    /// an ipv64 link.
    ///
    /// - Parameters:
    ///   - check: The check definition, as when creating.
    ///   - token: Optional token of an existing check.
    ///
    /// `POST /checks/online-test`
    public func onlineTest(_ check: Node64.CheckInput, token: String? = nil) async throws -> Node64.CheckOnlineTestResult {
        try await client.send(Request(.post, "/checks/online-test", body: .json(OnlineTestBody(check: check, token: token))))
    }
}

private struct BulkBody: Encodable, Sendable {
    let action: Node64.CheckBulkAction
    let tokens: [String]
    let tag: String?
}

private struct OnlineTestBody: Encodable, Sendable {
    let check: Node64.CheckInput
    let token: String?

    enum CodingKeys: String, CodingKey { case token }

    func encode(to encoder: any Encoder) throws {
        try check.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(token, forKey: .token)
    }
}
