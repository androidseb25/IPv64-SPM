import Foundation

extension Node64.HC {
    /// Proxmox VE systems monitoring.
    public var proxmox: Proxmox { Proxmox(client: client) }

    /// Endpoints of the Proxmox VE monitoring (tag *Healthchecks*).
    public struct Proxmox: Sendable { let client: Node64 }
}

extension Node64.HC.Proxmox {
    /// Monitored Proxmox systems (`/healthchecks/proxmox/systems`).
    public var systems: Systems { Systems(client: client) }

    /// Endpoints of the monitored Proxmox systems.
    public struct Systems: Sendable { let client: Node64 }
}

extension Node64.HC.Proxmox.Systems {
    /// Lists Proxmox systems with the state of the last query (without secret).
    ///
    /// - Parameter kind: `.pve` (default), `.docker` or `.all`.
    ///
    /// `GET /healthchecks/proxmox/systems`
    public func list(kind: Node64.PVEKindFilter? = nil) async throws -> [Node64.PVESystem] {
        try await client.send(Request(.get, "/healthchecks/proxmox/systems", query: [QueryItem("kind", kind)]))
    }

    /// Adds a Proxmox system and starts querying it immediately (if enabled).
    ///
    /// The secret is required and stored encrypted. Fails with 409 when no `secret.key` is loaded.
    ///
    /// `POST /healthchecks/proxmox/systems`
    public func create(_ input: Node64.PVESystemInput) async throws -> Node64.PVESystem {
        try await client.send(Request(.post, "/healthchecks/proxmox/systems", body: .json(input)))
    }

    /// Reads a Proxmox system.
    ///
    /// `GET /healthchecks/proxmox/systems/{id}`
    public func get(_ id: Int) async throws -> Node64.PVESystem {
        try await client.send(Request(.get, "/healthchecks/proxmox/systems/\(id)"))
    }

    /// Changes a Proxmox system; partial update, an empty secret keeps the stored one.
    ///
    /// Switching on or off pauses or starts the checks of the system.
    ///
    /// `PUT /healthchecks/proxmox/systems/{id}`
    public func update(_ id: Int, _ input: Node64.PVESystemInput) async throws -> Node64.PVESystem {
        try await client.send(Request(.put, "/healthchecks/proxmox/systems/\(id)", body: .json(input)))
    }

    /// Deletes a Proxmox system with its settings, history and the checks created with `asCheck`.
    ///
    /// `DELETE /healthchecks/proxmox/systems/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/healthchecks/proxmox/systems/\(id)"))
    }

    /// Returns the system with its nodes and guests from the last query.
    ///
    /// `GET /healthchecks/proxmox/systems/{id}/resources`
    public func resources(_ id: Int) async throws -> Node64.PVEResources {
        try await client.send(Request(.get, "/healthchecks/proxmox/systems/\(id)/resources"))
    }

    /// Returns the history of a node or guest.
    ///
    /// CPU, memory and disk are percent, network and disk I/O bytes per second. Resolution is
    /// 1 minute (up to 48 h), 5 minutes or 1 hour.
    ///
    /// - Parameters:
    ///   - id: ID of the system.
    ///   - key: `node/<name>`, `qemu/<vmid>`, `lxc/<vmid>` (or `docker/<name>` for Docker hosts).
    ///   - range: Time range, default `24h`.
    ///
    /// `GET /healthchecks/proxmox/systems/{id}/series`
    public func series(_ id: Int, key: String, range: Node64.PVESeriesRange? = nil) async throws -> Node64.PVESeries {
        try await client.send(Request(
            .get,
            "/healthchecks/proxmox/systems/\(id)/series",
            query: [QueryItem("key", key), QueryItem("range", range)]
        ))
    }

    /// Returns the settings of all levels and the effective rules.
    ///
    /// `GET /healthchecks/proxmox/systems/{id}/settings`
    public func settings(_ id: Int) async throws -> Node64.PVESettingsOverview {
        try await client.send(Request(.get, "/healthchecks/proxmox/systems/\(id)/settings"))
    }

    /// Sets the settings of one level. Partial update: only the fields you set change
    /// (``Node64/PVEExpectRunning/automatic`` explicitly sends `null`).
    ///
    /// `asCheck` creates (or deletes) the healthcheck of that level.
    ///
    /// - Parameters:
    ///   - id: ID of the system.
    ///   - key: Level; `nil` is the system, otherwise `node/<name>`, `qemu/<vmid>` or `lxc/<vmid>`.
    ///   - input: The changes.
    ///
    /// `PUT /healthchecks/proxmox/systems/{id}/settings`
    public func updateSettings(
        _ id: Int,
        key: String? = nil,
        _ input: Node64.PVESettingsInput
    ) async throws -> Node64.PVESettingsResult {
        try await client.send(Request(
            .put,
            "/healthchecks/proxmox/systems/\(id)/settings",
            query: [QueryItem("key", key)],
            body: .json(input)
        ))
    }

    /// Resets a level to "inherit everything". A check created with `asCheck` stays.
    ///
    /// - Parameter key: Level; `nil` is the system.
    ///
    /// `DELETE /healthchecks/proxmox/systems/{id}/settings`
    public func resetSettings(_ id: Int, key: String? = nil) async throws {
        try await client.sendWithoutContent(Request(
            .delete,
            "/healthchecks/proxmox/systems/\(id)/settings",
            query: [QueryItem("key", key)]
        ))
    }
}

extension Node64.HC.Proxmox {
    /// Tests a connection: fetches certificate fingerprint, version, cluster, nodes and guests.
    ///
    /// With `systemID` and no secret the stored secret is used. Not needed for Docker hosts (422).
    ///
    /// `POST /healthchecks/proxmox/probe`
    public func probe(_ input: Node64.PVESystemInput, systemID: Int? = nil) async throws -> Node64.PVEProbe {
        let body = ProbeBody(input: input, systemID: systemID)
        return try await client.send(Request(.post, "/healthchecks/proxmox/probe", body: .json(body)))
    }

    private struct ProbeBody: Encodable, Sendable {
        let input: Node64.PVESystemInput
        let systemID: Int?

        enum CodingKeys: String, CodingKey {
            case name, addresses
            case tokenID = "token_id"
            case secret
            case pinSHA256 = "pin_sha256"
            case interval, enabled
            case systemID = "system_id"
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(input.name, forKey: .name)
            try container.encodeIfPresent(input.addresses, forKey: .addresses)
            try container.encodeIfPresent(input.tokenID, forKey: .tokenID)
            try container.encodeIfPresent(input.secret, forKey: .secret)
            try container.encodeIfPresent(input.pinSHA256, forKey: .pinSHA256)
            try container.encodeIfPresent(input.interval, forKey: .interval)
            try container.encodeIfPresent(input.enabled, forKey: .enabled)
            try container.encodeIfPresent(systemID, forKey: .systemID)
        }
    }
}
