import Foundation

extension Node64.HC {
    /// Docker hosts and containers monitoring.
    public var docker: Docker { Docker(client: client) }

    /// Endpoints of the Docker monitoring (tag *Healthchecks*).
    public struct Docker: Sendable { let client: Node64 }
}

extension Node64.HC.Docker {
    /// Lists all containers of the local Docker host with monitoring values and Docker checks.
    ///
    /// Values such as CPU and memory are only present while monitoring runs (`monitored`).
    ///
    /// `GET /healthchecks/docker/containers`
    public func containers() async throws -> Node64.DockerContainers {
        try await client.send(Request(.get, "/healthchecks/docker/containers"))
    }

    /// Monitored Docker hosts (`/healthchecks/docker/systems`).
    public var systems: Systems { Systems(client: client) }

    /// Endpoints of the monitored Docker hosts. They share the data model of the Proxmox systems.
    public struct Systems: Sendable { let client: Node64 }
}

extension Node64.HC.Docker.Systems {
    /// Lists the Docker hosts of the monitoring with their state; `guests` counts the containers
    /// (without label `node64.nomonitor`).
    ///
    /// `GET /healthchecks/docker/systems`
    public func list() async throws -> [Node64.PVESystem] {
        try await client.send(Request(.get, "/healthchecks/docker/systems"))
    }

    /// Adds a Docker host.
    ///
    /// With a reachable socket Node64 sets up the local host automatically; after removing it,
    /// use this method again. Without `addresses` it uses `NODE64_DOCKER_HOST` or
    /// `unix:///var/run/docker.sock`. There is no token or secret.
    ///
    /// - Parameters:
    ///   - name: Name, e.g. `Docker`.
    ///   - addresses: Docker host addresses.
    ///   - interval: Query interval in seconds (15 to 300, default 30).
    ///   - enabled: Switch monitoring on or off.
    ///
    /// `POST /healthchecks/docker/systems`
    public func create(
        name: String? = nil,
        addresses: [String]? = nil,
        interval: Int? = nil,
        enabled: Bool? = nil
    ) async throws -> Node64.PVESystem {
        let body = CreateBody(name: name, addresses: addresses, interval: interval, enabled: enabled)
        return try await client.send(Request(.post, "/healthchecks/docker/systems", body: .json(body)))
    }

    /// Reads a Docker host (same data as for Proxmox systems).
    ///
    /// `GET /healthchecks/docker/systems/{id}`
    public func get(_ id: Int) async throws -> Node64.PVESystem {
        try await client.send(Request(.get, "/healthchecks/docker/systems/\(id)"))
    }

    /// Changes a Docker host (name, interval, on/off); partial update, only the fields you set change.
    ///
    /// Switching on or off pauses or starts the checks of the system.
    ///
    /// `PUT /healthchecks/docker/systems/{id}`
    public func update(_ id: Int, _ input: Node64.PVESystemInput) async throws -> Node64.PVESystem {
        try await client.send(Request(.put, "/healthchecks/docker/systems/\(id)", body: .json(input)))
    }

    /// Removes a Docker host with its settings and history.
    ///
    /// Docker checks stay, but there is no automatic set-up any more. Checks created with
    /// `asCheck` are deleted.
    ///
    /// `DELETE /healthchecks/docker/systems/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/healthchecks/docker/systems/\(id)"))
    }

    /// Returns the Docker host with the containers from the last query.
    ///
    /// `GET /healthchecks/docker/systems/{id}/resources`
    public func resources(_ id: Int) async throws -> Node64.PVEResources {
        try await client.send(Request(.get, "/healthchecks/docker/systems/\(id)/resources"))
    }

    /// Returns the history of a container.
    ///
    /// CPU, memory and disk are percent, network and disk I/O bytes per second. Resolution is
    /// 1 minute (up to 48 h), 5 minutes or 1 hour.
    ///
    /// - Parameters:
    ///   - id: ID of the Docker host.
    ///   - key: Container key `docker/<name>`.
    ///   - range: Time range, default `24h`.
    ///
    /// `GET /healthchecks/docker/systems/{id}/series`
    public func series(_ id: Int, key: String, range: Node64.PVESeriesRange? = nil) async throws -> Node64.PVESeries {
        try await client.send(Request(
            .get,
            "/healthchecks/docker/systems/\(id)/series",
            query: [QueryItem("key", key), QueryItem("range", range)]
        ))
    }

    /// Returns the settings of all levels of a Docker host and the effective rules.
    ///
    /// `GET /healthchecks/docker/systems/{id}/settings`
    public func settings(_ id: Int) async throws -> Node64.PVESettingsOverview {
        try await client.send(Request(.get, "/healthchecks/docker/systems/\(id)/settings"))
    }

    /// Sets the settings of one level. Partial update: only the fields you set change
    /// (``Node64/PVEExpectRunning/automatic`` explicitly sends `null`).
    ///
    /// `asCheck` creates (or deletes) a healthcheck of type `docker`.
    ///
    /// - Parameters:
    ///   - id: ID of the Docker host.
    ///   - key: Level; `nil` is the system, otherwise `docker/<name>`.
    ///   - input: The changes.
    ///
    /// `PUT /healthchecks/docker/systems/{id}/settings`
    public func updateSettings(
        _ id: Int,
        key: String? = nil,
        _ input: Node64.PVESettingsInput
    ) async throws -> Node64.PVESettingsResult {
        try await client.send(Request(
            .put,
            "/healthchecks/docker/systems/\(id)/settings",
            query: [QueryItem("key", key)],
            body: .json(input)
        ))
    }

    /// Resets a level to "inherit everything". A check created with `asCheck` stays.
    ///
    /// - Parameter key: Level; `nil` is the system.
    ///
    /// `DELETE /healthchecks/docker/systems/{id}/settings`
    public func resetSettings(_ id: Int, key: String? = nil) async throws {
        try await client.sendWithoutContent(Request(
            .delete,
            "/healthchecks/docker/systems/\(id)/settings",
            query: [QueryItem("key", key)]
        ))
    }

    private struct CreateBody: Encodable, Sendable {
        let name: String?
        let addresses: [String]?
        let interval: Int?
        let enabled: Bool?

        enum CodingKeys: String, CodingKey {
            case name, addresses, interval, enabled
        }
    }
}
