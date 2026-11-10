import Foundation

extension Node64.Sonar64 {
    /// State of the node, the own node at ipv64 and the trust level.
    ///
    /// Without participation `node` is empty. `me` holds the exact location (local only). The Sonar token is never returned.
    /// Fails with `404` when the module is switched off.
    ///
    /// `GET /sonar64/status`
    public func status() async throws -> Node64.Sonar64Status {
        try await client.send(Request(.get, "/sonar64/status"))
    }

    /// Latest own measurements and probes answered live on UDP 6464, newest first, without target addresses.
    ///
    /// - Parameter n: Number of entries, 1–200 (`400` otherwise).
    ///
    /// `GET /sonar64/recent`
    public func recent(n: Int? = nil) async throws -> Node64.Sonar64Recent {
        try await client.send(Request(.get, "/sonar64/recent", query: [QueryItem("n", n)]))
    }

    /// Who measured this node, taken from the results at ipv64.
    ///
    /// Delayed by up to 5 minutes, cached for one minute, at most 500 rows. `ready` is `false` while the node is not
    /// registered. Fails with `502` when ipv64 is unreachable.
    ///
    /// - Parameter since: Only rows from this time on.
    ///
    /// `GET /sonar64/inbound`
    public func inbound(since: Date? = nil) async throws -> Node64.Sonar64Inbound {
        try await client.send(Request(.get, "/sonar64/inbound", query: [QueryItem("since", since)]))
    }

    /// Local settings and the profile at ipv64.
    ///
    /// `GET /sonar64/settings`
    public func settings() async throws -> Node64.Sonar64Settings {
        try await client.send(Request(.get, "/sonar64/settings"))
    }

    /// Changes participation, role, budget, quiet hours and profile. Omitted fields stay unchanged (partial update).
    ///
    /// `participate: true` needs the central ipv64 API key (creates a Sonar token if none exists).
    /// `participate: false` leaves the network: the node is unregistered at ipv64 and token, key and node ID are deleted
    /// (only locally if ipv64 is unreachable). Profile fields go to ipv64 and need a registered node.
    /// `measured: true` opens UDP 6464; some other participants then see the public IP (only in the measurement plan).
    /// Errors: `400` invalid JSON or unknown field, `409` no API key or node not registered, `422` invalid field
    /// (see `fields`), `502` ipv64 reports an error.
    ///
    /// `PUT /sonar64/settings`
    public func updateSettings(_ input: Node64.Sonar64SettingsInput) async throws -> Node64.Sonar64Settings {
        try await client.send(Request(.put, "/sonar64/settings", body: .json(input)))
    }
}
