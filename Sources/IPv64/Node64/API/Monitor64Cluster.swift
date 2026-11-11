import Foundation

extension Node64.Monitor64 {
    /// Cluster responsibility, node keys and orphaned hosts.
    public var cluster: Cluster { Cluster(client: client) }

    /// Cluster endpoints of Monitor64.
    public struct Cluster: Sendable { let client: Node64 }

    /// Overview: counters per state, open problems, recent events and all hosts with their current state.
    ///
    /// `GET /monitor64/overview`
    public func overview() async throws -> Node64.Monitor64Overview {
        try await client.send(Request(.get, "/monitor64/overview"))
    }

    /// Mini history of the last 24 hours: up to 48 averages per key.
    ///
    /// Without `host`: CPU load per host (key: host UID). With `host`: the first metric with a threshold per
    /// service (key: service). In a cluster, values of other nodes' hosts come from the responsible node (missing
    /// if unreachable). An empty object when the history is not running.
    ///
    /// - Parameter host: UID of the host (optional).
    ///
    /// `GET /monitor64/sparks`
    public func sparks(host: String? = nil) async throws -> [String: [Double]] {
        try await client.send(Request(.get, "/monitor64/sparks", query: [QueryItem("host", host)]))
    }

    /// Chart series of a host.
    ///
    /// Time range: `range` (with `offset` ranges back) or `from`/`to` (zoom, takes precedence); the last 24 hours
    /// without any. The resolution follows the range (raw, 5 min, 1 h). Fails with `400` (`series`) for an invalid
    /// query and `503` (`not_running`) when the module is not running.
    ///
    /// - Parameters:
    ///   - host: UID of the host.
    ///   - series: 1–16 series in the form `service|metric`.
    ///   - range: Time range.
    ///   - offset: Number of ranges back, 0–1000.
    ///   - from: Start in Unix seconds (only with `to`).
    ///   - to: End in Unix seconds (after `from`).
    ///   - points: At most this many points per series, 1–700 (default 700).
    ///
    /// `GET /monitor64/series`
    public func series(
        host: String,
        series: [String],
        range: Node64.Monitor64SeriesRange? = nil,
        offset: Int? = nil,
        from: Int? = nil,
        to: Int? = nil,
        points: Int? = nil
    ) async throws -> Node64.Monitor64Series {
        var query = [QueryItem("host", host)] + series.map { QueryItem("s", $0) }
        query += [
            QueryItem("range", range), QueryItem("off", offset),
            QueryItem("from", from), QueryItem("to", to), QueryItem("points", points),
        ]
        return try await client.send(Request(.get, "/monitor64/series", query: query))
    }

    /// Technical state: scheduler, size of the history, memory, load generator.
    ///
    /// `GET /monitor64/status`
    public func status() async throws -> Node64.Monitor64Status {
        try await client.send(Request(.get, "/monitor64/status"))
    }

    /// Settings: default interval, concurrent queries, history retention, public node key, trap receiver, push port and technical state.
    ///
    /// `GET /monitor64/settings`
    public func settings() async throws -> Node64.Monitor64Settings {
        try await client.send(Request(.get, "/monitor64/settings"))
    }

    /// Saves the settings. `interval` and `workers` are always required; `nil` ports stay unchanged.
    ///
    /// The ports apply immediately, `workers` after the next start of the module. If the new push port is in use
    /// or cannot be opened, nothing is applied and the old port stays open. Errors: `400` with `json`, `interval`,
    /// `workers`, `trap_port`, `push_port`, `push_port_used` or `push_port_bind`.
    ///
    /// `PUT /monitor64/settings`
    @discardableResult
    public func updateSettings(_ input: Node64.Monitor64SettingsInput) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.put, "/monitor64/settings", body: .json(input)))
    }
}

extension Node64.Monitor64.Cluster {
    /// Nodes, responsibility per host (view of this node) and the keys of this node.
    ///
    /// `GET /monitor64/cluster`
    public func get() async throws -> Node64.Monitor64Cluster {
        try await client.send(Request(.get, "/monitor64/cluster"))
    }

    /// Which node monitors each host, taken from the stored state; without `host` the orphaned hosts are included.
    ///
    /// - Parameter host: Only this host (UID).
    ///
    /// `GET /monitor64/cluster/views`
    public func views(host: String? = nil) async throws -> Node64.Monitor64ClusterViews {
        try await client.send(Request(.get, "/monitor64/cluster/views", query: [QueryItem("host", host)]))
    }

    /// Responsibility of a host: members, setting, view and the latest takeovers and handbacks. `404` if unknown.
    ///
    /// `GET /monitor64/cluster/hosts/{uid}`
    public func host(_ uid: String) async throws -> Node64.Monitor64ClusterHostInfo {
        try await client.send(Request(.get, "/monitor64/cluster/hosts/\(uid)"))
    }

    /// Sets the preferred node and the backup nodes of a host (only nodes of this cluster, or this node).
    ///
    /// The node responsible so far stays until the new preferred node has been reachable long enough.
    /// Errors: `400` (`json`, `cluster_node` for an unknown node), `404`.
    /// Send both fields: the spec does not say what a missing `preferredNode` means (empty = this node).
    ///
    /// `PUT /monitor64/cluster/hosts/{uid}`
    public func updateHost(_ uid: String, _ input: Node64.Monitor64ClusterHostInput) async throws -> Node64.Monitor64ClusterHostUpdate {
        try await client.send(Request(.put, "/monitor64/cluster/hosts/\(uid)", body: .json(input)))
    }

    /// Tests the accesses of a host from all reachable nodes (to suggest backup nodes); has a time limit. `404` if unknown.
    ///
    /// `POST /monitor64/cluster/hosts/{uid}/reach`
    public func testReach(_ uid: String) async throws -> Node64.Monitor64ClusterReach {
        try await client.send(Request(.post, "/monitor64/cluster/hosts/\(uid)/reach"))
    }

    /// Keys of this node: fingerprint, `authorized_keys` line, old keys and open conversions (no private key).
    ///
    /// `GET /monitor64/cluster/keys`
    public func keys() async throws -> Node64.Monitor64ClusterKeys {
        try await client.send(Request(.get, "/monitor64/cluster/keys"))
    }

    /// Creates a new key for all nodes. Sensitive: agents are converted in the background (poll ``keys()`` while
    /// `running`); SSH hosts need the new line (`authorizedKey`) added by hand and then ``confirmKey(accessUID:)``.
    /// The old keys stay offered until ``retireKeys()``. Fails with `503` (`not_running`) if the module is off.
    ///
    /// `POST /monitor64/cluster/keys/rotate`
    public func rotateKey() async throws -> Node64.Monitor64ClusterKeys {
        try await client.send(Request(.post, "/monitor64/cluster/keys/rotate"))
    }

    /// Confirms the manual conversion of one SSH access (line added by hand), or discards the entry; applies cluster-wide.
    /// `404` when no conversion is open for the access.
    ///
    /// - Parameter accessUID: UID of the access.
    ///
    /// `POST /monitor64/cluster/keys/confirm`
    public func confirmKey(accessUID: String) async throws -> Node64.Monitor64ClusterKeys {
        try await client.send(Request(.post, "/monitor64/cluster/keys/confirm", body: .json(ConfirmBody(accessUID: accessUID))))
    }

    /// Retries the agents not yet converted, in the background; poll ``keys()`` while `running`. `503` (`not_running`) if the module is off.
    ///
    /// `POST /monitor64/cluster/keys/retry`
    public func retryKeys() async throws -> Node64.Monitor64ClusterKeys {
        try await client.send(Request(.post, "/monitor64/cluster/keys/retry"))
    }

    /// Discards the old keys immediately. Destructive: agents that were not converted are locked out afterwards.
    ///
    /// `POST /monitor64/cluster/keys/retire`
    public func retireKeys() async throws -> Node64.Monitor64ClusterKeys {
        try await client.send(Request(.post, "/monitor64/cluster/keys/retire"))
    }

    /// Hosts that no node monitors any more, with reason and previous node.
    ///
    /// `GET /monitor64/cluster/orphans`
    public func orphans() async throws -> Node64.Monitor64Orphans {
        try await client.send(Request(.get, "/monitor64/cluster/orphans"))
    }

    /// Assigns orphaned hosts to this node. Only affects hosts that are orphaned right now; other UIDs are skipped.
    /// `400` (`json`) if neither `uids` nor `all` is set.
    ///
    /// `POST /monitor64/cluster/orphans/assign`
    public func assignOrphans(_ input: Node64.Monitor64OrphanInput) async throws -> Node64.Monitor64OrphanResult {
        try await client.send(Request(.post, "/monitor64/cluster/orphans/assign", body: .json(input)))
    }

    /// Removes orphaned hosts. Destructive: the hosts are deleted. Only affects hosts that are orphaned right now;
    /// other UIDs are skipped. `400` (`json`) if neither `uids` nor `all` is set.
    ///
    /// `POST /monitor64/cluster/orphans/remove`
    public func removeOrphans(_ input: Node64.Monitor64OrphanInput) async throws -> Node64.Monitor64OrphanResult {
        try await client.send(Request(.post, "/monitor64/cluster/orphans/remove", body: .json(input)))
    }

    private struct ConfirmBody: Encodable, Sendable {
        let accessUID: String
        enum CodingKeys: String, CodingKey { case accessUID = "access_uid" }
    }
}
