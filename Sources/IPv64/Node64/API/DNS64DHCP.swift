import Foundation

extension Node64.DNS64 {
    /// DHCP server.
    public var dhcp: DHCP { DHCP(client: client) }

    /// DHCP server endpoints of DNS64.
    public struct DHCP: Sendable { let client: Node64 }
}

extension Node64.DNS64.DHCP {
    /// DHCP networks.
    public var scopes: Scopes { Scopes(client: client) }
    /// Fixed addresses.
    public var reservations: Reservations { Reservations(client: client) }

    /// DHCP network endpoints.
    public struct Scopes: Sendable { let client: Node64 }
    /// Fixed DHCP address endpoints.
    public struct Reservations: Sendable { let client: Node64 }

    /// Switch and state of the DHCP server: `mode`, `role`, `standby` (networks where a reserve node stays
    /// silent), `conflicts` (network to other primary nodes serving it), `running`, `docker_bridge` and `state`
    /// with networks (usage, errors, leases), recent requests, foreign DHCP servers and counters.
    ///
    /// The spec documents no schema, so the raw JSON is returned.
    ///
    /// `GET /dns64/dhcp`
    public func status() async throws -> JSONValue {
        try await client.sendJSON(Request(.get, "/dns64/dhcp"))
    }

    /// Switches the DHCP server on this node (never cluster-wide). Answers `400` if invalid or for a Docker bridge network.
    ///
    /// The spec documents no response body, so the raw JSON is returned.
    ///
    /// - Parameter mode: `off`, `observe` (dry run) or `on`.
    ///
    /// `PUT /dns64/dhcp/mode`
    @discardableResult
    public func setMode(_ mode: Node64.DNS64DHCPMode) async throws -> JSONValue {
        try await client.sendJSON(Request(.put, "/dns64/dhcp/mode", body: .json(ModeBody(mode: mode))))
    }

    /// Sets the role of this node in the cluster (per node). A `primary` hands out addresses; a `reserve` only
    /// answers if no node with the cluster scope "DHCP networks" is reachable and none answered as DHCP server in the last 3 minutes.
    ///
    /// The spec documents no response body, so the raw JSON is returned.
    ///
    /// `PUT /dns64/dhcp/role`
    @discardableResult
    public func setRole(_ role: Node64.DNS64DHCPRole) async throws -> JSONValue {
        try await client.sendJSON(Request(.put, "/dns64/dhcp/role", body: .json(RoleBody(role: role))))
    }

    /// Releases an assigned address (lease).
    ///
    /// - Parameters:
    ///   - scope: ID of the DHCP network.
    ///   - mac: MAC address of the client, e.g. `aa:bb:cc:dd:ee:ff` (path-encoded; colons stay literal).
    ///
    /// `DELETE /dns64/dhcp/leases/{scope}/{mac}`
    public func releaseLease(scope: Int, mac: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dns64/dhcp/leases/\(scope)/\(mac)"))
    }

    /// IPv6 DNS via Router Advertisement: settings and state. Per node, never cluster-wide.
    /// The node announces itself only as DNS server (RDNSS/DNSSL, router lifetime 0, no prefixes);
    /// `routers` are the advertisements of other routers (only while the sender runs).
    ///
    /// `GET /dns64/dhcp/ipv6`
    public func ipv6() async throws -> Node64.DNS64DHCPIPv6State {
        try await client.send(Request(.get, "/dns64/dhcp/ipv6"))
    }

    /// Configures IPv6 DNS via Router Advertisement. Turning it on needs at least one (at most 8) interface
    /// and host networking; the ULA address of the interface is announced, otherwise the global one.
    /// Fields left `nil` are not sent. Answers `400` if invalid.
    ///
    /// The spec documents no response body, so the raw JSON is returned.
    ///
    /// `PUT /dns64/dhcp/ipv6`
    @discardableResult
    public func updateIPv6(_ input: Node64.DNS64DHCPIPv6Input) async throws -> JSONValue {
        try await client.sendJSON(Request(.put, "/dns64/dhcp/ipv6", body: .json(input)))
    }

    /// Asks the network for routers (Router Solicitation, takes 3 s), on the selected interfaces, otherwise on all with IPv6.
    ///
    /// `POST /dns64/dhcp/ipv6/probe`
    public func probeIPv6() async throws -> Node64.DNS64DHCPIPv6Probe {
        try await client.send(Request(.post, "/dns64/dhcp/ipv6/probe"))
    }

    private struct ModeBody: Encodable, Sendable { let mode: Node64.DNS64DHCPMode }
    private struct RoleBody: Encodable, Sendable { let role: Node64.DNS64DHCPRole }
}

extension Node64.DNS64.DHCP.Scopes {
    /// DHCP networks.
    ///
    /// `GET /dns64/dhcp/scopes`
    public func list() async throws -> [Node64.DNS64DHCPScope] {
        try await client.send(Request(.get, "/dns64/dhcp/scopes"))
    }

    /// Creates a DHCP network (one per interface). New networks are turned on. Answers `400` if invalid.
    ///
    /// `POST /dns64/dhcp/scopes`
    public func create(_ input: Node64.DNS64DHCPScopeInput) async throws -> Node64.DNS64DHCPScope {
        try await client.send(Request(.post, "/dns64/dhcp/scopes", body: .json(input)))
    }

    /// Changes a DHCP network. The enabled state stays as it is and the network itself cannot be changed.
    ///
    /// Sends the complete object (`interface`, `subnet`, `range_start` and `range_end` are required);
    /// build `input` from the current network and change what you need.
    ///
    /// `PUT /dns64/dhcp/scopes/{id}`
    public func update(_ id: Int, _ input: Node64.DNS64DHCPScopeInput) async throws -> Node64.DNS64DHCPScope {
        try await client.send(Request(.put, "/dns64/dhcp/scopes/\(id)", body: .json(input)))
    }

    /// Deletes a DHCP network together with its fixed addresses and leases.
    ///
    /// `DELETE /dns64/dhcp/scopes/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dns64/dhcp/scopes/\(id)"))
    }

    /// Turns a DHCP network on.
    ///
    /// `POST /dns64/dhcp/scopes/{id}/enable`
    public func enable(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.post, "/dns64/dhcp/scopes/\(id)/enable"))
    }

    /// Turns a DHCP network off.
    ///
    /// `POST /dns64/dhcp/scopes/{id}/disable`
    public func disable(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.post, "/dns64/dhcp/scopes/\(id)/disable"))
    }
}

extension Node64.DNS64.DHCP.Reservations {
    /// Fixed DHCP addresses.
    ///
    /// `GET /dns64/dhcp/reservations`
    public func list() async throws -> [Node64.DNS64DHCPReservation] {
        try await client.send(Request(.get, "/dns64/dhcp/reservations"))
    }

    /// Creates a fixed address. MAC and IP are unique per network. Answers `400` if invalid.
    ///
    /// `POST /dns64/dhcp/reservations`
    public func create(_ input: Node64.DNS64DHCPReservationInput) async throws -> Node64.DNS64DHCPReservation {
        try await client.send(Request(.post, "/dns64/dhcp/reservations", body: .json(input)))
    }

    /// Changes a fixed address.
    ///
    /// Sends the complete object (`scope_id`, `mac` and `ip` are required); build `input` from the current
    /// reservation. `groupID` only has an effect when creating.
    ///
    /// `PUT /dns64/dhcp/reservations/{id}`
    public func update(_ id: Int, _ input: Node64.DNS64DHCPReservationInput) async throws -> Node64.DNS64DHCPReservation {
        try await client.send(Request(.put, "/dns64/dhcp/reservations/\(id)", body: .json(input)))
    }

    /// Deletes a fixed address.
    ///
    /// `DELETE /dns64/dhcp/reservations/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dns64/dhcp/reservations/\(id)"))
    }
}
