import Foundation

extension IPv64 {
    /// WireGuard gateways of Cloud Routers, including OSPF, port forwards and peers.
    ///
    /// Most changes are applied asynchronously and answer `202 Accepted` with the
    /// new state; poll until `state == ready`. While a gateway is being set up,
    /// changes fail with `409 gateway_busy` and a `retry_after` hint.
    public var gateways: Gateways { Gateways(client: self) }

    /// Endpoints of the *Gateways* area.
    public struct Gateways: Sendable {
        let client: IPv64

        /// Returns a gateway with its peers.
        ///
        /// `GET /gateways/{token}`
        public func get(_ gateway: String) async throws -> Gateway {
            try await client.send(Request(.get, "/gateways/\(gateway)"))
        }

        /// Changes a gateway. Addresses are in CIDR notation; an empty string removes the address.
        ///
        /// `PATCH /gateways/{token}`
        /// - Parameters:
        ///   - gateway: Gateway token.
        ///   - name: Name.
        ///   - ipv4: Gateway IPv4 address, e.g. `10.7.0.1/24`.
        ///   - ipv6: Gateway IPv6 address, e.g. `fd64::1/64`.
        ///   - disabled: Disable or enable the gateway.
        public func update(
            _ gateway: String,
            name: String? = nil,
            ipv4: String? = nil,
            ipv6: String? = nil,
            disabled: Bool? = nil
        ) async throws -> Gateway {
            let body = UpdateBody(name: name, ipv4: ipv4, ipv6: ipv6, disabled: disabled)
            return try await client.send(Request(.patch, "/gateways/\(gateway)", body: .json(body)))
        }

        /// Deletes a gateway with all its peers.
        ///
        /// Asynchronous: answers `202 Accepted` with state `deleting`.
        ///
        /// `DELETE /gateways/{token}`
        public func delete(_ gateway: String) async throws -> Gateway {
            try await client.send(Request(.delete, "/gateways/\(gateway)"))
        }

        /// Generates a new key pair for the gateway. All peers must receive the new configuration afterwards.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /gateways/{token}/rotate-keys`
        public func rotateKeys(_ gateway: String) async throws -> Gateway {
            try await client.send(Request(.post, "/gateways/\(gateway)/rotate-keys"))
        }

        /// Resets the traffic counters.
        ///
        /// `POST /gateways/{token}/reset-traffic`
        public func resetTraffic(_ gateway: String) async throws -> Gateway {
            try await client.send(Request(.post, "/gateways/\(gateway)/reset-traffic"))
        }

        /// Enables OSPF or changes its settings.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `PUT /gateways/{token}/ospf`
        /// - Parameters:
        ///   - gateway: Gateway token.
        ///   - areaID: OSPF area, e.g. `0.0.0.0`.
        ///   - version: OSPF version, e.g. `2`.
        ///   - cost: Link cost, e.g. `10`.
        public func enableOSPF(
            _ gateway: String,
            areaID: String? = nil,
            version: Int? = nil,
            cost: Int? = nil
        ) async throws -> Gateway {
            let body = OSPFBody(areaID: areaID, version: version, cost: cost)
            return try await client.send(Request(.put, "/gateways/\(gateway)/ospf", body: .json(body)))
        }

        /// Disables OSPF.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `DELETE /gateways/{token}/ospf`
        public func disableOSPF(_ gateway: String) async throws -> Gateway {
            try await client.send(Request(.delete, "/gateways/\(gateway)/ospf"))
        }

        /// Port forwards of the gateway.
        public var portForwards: PortForwards { PortForwards(client: client) }
        /// Peers of the gateway.
        public var peers: Peers { Peers(client: client) }

        private struct UpdateBody: Encodable, Sendable {
            let name: String?
            let ipv4: String?
            let ipv6: String?
            let disabled: Bool?
        }

        private struct OSPFBody: Encodable, Sendable {
            let areaID: String?
            let version: Int?
            let cost: Int?

            enum CodingKeys: String, CodingKey {
                case areaID = "area_id"
                case version
                case cost
            }
        }
    }
}

extension IPv64.Gateways {
    /// Port forwards of a gateway.
    public struct PortForwards: Sendable {
        let client: IPv64

        /// Lists the port forwards of a gateway.
        ///
        /// `GET /gateways/{token}/port-forwards`
        public func list(gateway: String) async throws -> [PortForward] {
            try await client.send(Request(.get, "/gateways/\(gateway)/port-forwards"))
        }

        /// Creates a port forward. The server assigns the public port, available afterwards in `publicPort`.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /gateways/{token}/port-forwards`
        /// - Parameters:
        ///   - gateway: Gateway token.
        ///   - destination: Destination IP inside the tunnel, e.g. `10.7.0.2`.
        ///   - targetPort: Destination port.
        ///   - protocol: `tcp` or `udp`.
        ///   - name: Name.
        ///   - publicIP: `server` or `router` (public IP of the router, create it first).
        public func create(
            gateway: String,
            destination: String,
            targetPort: Int,
            protocol: PortForwardProtocol,
            name: String? = nil,
            publicIP: PortForwardPublicIP? = nil
        ) async throws -> PortForward {
            let body = Body(
                destination: destination,
                targetPort: targetPort,
                protocol: `protocol`,
                name: name,
                publicIP: publicIP
            )
            return try await client.send(Request(.post, "/gateways/\(gateway)/port-forwards", body: .json(body)))
        }

        /// Enables or disables a port forward.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `PATCH /gateways/{token}/port-forwards/{id}`
        public func setDisabled(_ id: Int, gateway: String, disabled: Bool) async throws -> PortForward {
            let body = DisabledBody(disabled: disabled)
            return try await client.send(Request(.patch, "/gateways/\(gateway)/port-forwards/\(id)", body: .json(body)))
        }

        /// Deletes a port forward.
        ///
        /// Asynchronous: answers `202 Accepted` with state `deleting`.
        ///
        /// `DELETE /gateways/{token}/port-forwards/{id}`
        public func delete(_ id: Int, gateway: String) async throws -> CloudRouterDeletion {
            try await client.send(Request(.delete, "/gateways/\(gateway)/port-forwards/\(id)"))
        }

        private struct DisabledBody: Encodable, Sendable {
            let disabled: Bool
        }

        private struct Body: Encodable, Sendable {
            let destination: String
            let targetPort: Int
            let `protocol`: PortForwardProtocol
            let name: String?
            let publicIP: PortForwardPublicIP?

            enum CodingKeys: String, CodingKey {
                case destination
                case targetPort = "target_port"
                case `protocol`
                case name
                case publicIP = "public_ip"
            }
        }
    }

    /// Peers of a gateway.
    public struct Peers: Sendable {
        let client: IPv64

        /// Lists the peers of a gateway.
        ///
        /// `GET /gateways/{token}/peers`
        public func list(gateway: String) async throws -> [Peer] {
            try await client.send(Request(.get, "/gateways/\(gateway)/peers"))
        }

        /// Creates a peer. Keys and addresses are assigned automatically.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        /// Fails with `409 gateway_busy` (see `retry_after`) while the gateway is being set up.
        ///
        /// `POST /gateways/{token}/peers`
        public func create(gateway: String, name: String? = nil) async throws -> Peer {
            try await client.send(Request(.post, "/gateways/\(gateway)/peers", body: .json(Body(name: name))))
        }

        private struct Body: Encodable, Sendable {
            let name: String?
        }
    }
}
