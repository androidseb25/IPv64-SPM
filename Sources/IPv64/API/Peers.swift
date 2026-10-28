import Foundation

extension IPv64 {
    /// WireGuard peers.
    ///
    /// Most changes are applied asynchronously at the gateway and answer
    /// `202 Accepted` with the new state; poll until `state == ready`. While a
    /// peer or its gateway is being set up, changes fail with `409` and a
    /// `retry_after` hint.
    public var peers: Peers { Peers(client: self) }

    /// Endpoints of the *Peers* area.
    public struct Peers: Sendable {
        let client: IPv64

        /// Returns a peer with its AllowedIPs.
        ///
        /// `GET /peers/{token}`
        public func get(_ peer: String) async throws -> Peer {
            try await client.send(Request(.get, "/peers/\(peer)"))
        }

        /// Changes a peer.
        ///
        /// `name` and `dnsServer` take effect immediately (`200`); all other fields are applied at the
        /// gateway (`202 Accepted`, wait for `state == ready`).
        ///
        /// `PATCH /peers/{token}`
        public func update(_ peer: String, _ input: PeerInput) async throws -> Peer {
            try await client.send(Request(.patch, "/peers/\(peer)", body: .json(input)))
        }

        /// Deletes a peer.
        ///
        /// Asynchronous: answers `202 Accepted` with state `deleting`.
        ///
        /// `DELETE /peers/{token}`
        public func delete(_ peer: String) async throws -> Peer {
            try await client.send(Request(.delete, "/peers/\(peer)"))
        }

        /// Returns the WireGuard configuration (`.conf` file contents, `text/plain`).
        ///
        /// The configuration contains the peer's private key.
        ///
        /// `GET /peers/{token}/config`
        public func config(_ peer: String) async throws -> String {
            try await client.sendText(Request(.get, "/peers/\(peer)/config"))
        }

        /// Generates a new key pair for the peer.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /peers/{token}/rotate-keys`
        public func rotateKeys(_ peer: String) async throws -> Peer {
            try await client.send(Request(.post, "/peers/\(peer)/rotate-keys"))
        }

        /// Generates a new preshared key.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /peers/{token}/rotate-preshared-key`
        public func rotatePresharedKey(_ peer: String) async throws -> Peer {
            try await client.send(Request(.post, "/peers/\(peer)/rotate-preshared-key"))
        }

        /// Sets your own keys. Without `privateKey` only the public key is stored and the config contains no private key.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `PUT /peers/{token}/keys`
        /// - Parameters:
        ///   - peer: Peer token.
        ///   - publicKey: Public key (Base64).
        ///   - privateKey: Private key; must match the public key.
        ///   - presharedKey: Preshared key (Base64).
        public func setKeys(
            _ peer: String,
            publicKey: String,
            privateKey: String? = nil,
            presharedKey: String? = nil
        ) async throws -> Peer {
            let body = KeysBody(publicKey: publicKey, privateKey: privateKey, presharedKey: presharedKey)
            return try await client.send(Request(.put, "/peers/\(peer)/keys", body: .json(body)))
        }

        /// Adds an additional network to the client config, e.g. a network behind another peer.
        ///
        /// Answers `201 Created` with the updated peer.
        ///
        /// `POST /peers/{token}/allowed-ips`
        /// - Parameter network: IP or network in CIDR, e.g. `192.168.50.0/24`.
        public func addAllowedIP(_ peer: String, network: String) async throws -> Peer {
            try await client.send(Request(.post, "/peers/\(peer)/allowed-ips", body: .json(NetworkBody(network: network))))
        }

        /// Removes an AllowedIP.
        ///
        /// `DELETE /peers/{token}/allowed-ips/{id}`
        public func removeAllowedIP(_ id: Int, peer: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/peers/\(peer)/allowed-ips/\(id)"))
        }

        private struct KeysBody: Encodable, Sendable {
            let publicKey: String
            let privateKey: String?
            let presharedKey: String?

            enum CodingKeys: String, CodingKey {
                case publicKey = "public_key"
                case privateKey = "private_key"
                case presharedKey = "preshared_key"
            }
        }

        private struct NetworkBody: Encodable, Sendable {
            let network: String
        }
    }
}

/// Fields to change with ``IPv64/Peers/update(_:_:)``. Only non-`nil` fields are sent.
public struct PeerInput: Encodable, Hashable, Sendable {
    /// Name.
    public var name: String?
    /// DNS server for the client config; empty string means none.
    public var dnsServer: String?
    /// Keepalive as `hh:mm:ss`, e.g. `00:00:25`.
    public var keepalive: String?
    /// Fixed endpoint (IP or hostname).
    public var endpoint: String?
    /// Port of the endpoint.
    public var endpointPort: Int?
    /// Tunnel IPv4 in CIDR, e.g. `10.7.0.5/32`.
    public var ipv4: String?
    /// Tunnel IPv6 in CIDR, e.g. `fd64::5/128`.
    public var ipv6: String?
    /// Disable or enable the peer.
    public var disabled: Bool?
    /// Mark as site-to-site peer.
    public var siteToSite: Bool?

    /// Creates a peer change set; only non-`nil` fields are sent.
    public init(
        name: String? = nil,
        dnsServer: String? = nil,
        keepalive: String? = nil,
        endpoint: String? = nil,
        endpointPort: Int? = nil,
        ipv4: String? = nil,
        ipv6: String? = nil,
        disabled: Bool? = nil,
        siteToSite: Bool? = nil
    ) {
        self.name = name
        self.dnsServer = dnsServer
        self.keepalive = keepalive
        self.endpoint = endpoint
        self.endpointPort = endpointPort
        self.ipv4 = ipv4
        self.ipv6 = ipv6
        self.disabled = disabled
        self.siteToSite = siteToSite
    }

    enum CodingKeys: String, CodingKey {
        case name
        case dnsServer = "dns_server"
        case keepalive, endpoint
        case endpointPort = "endpoint_port"
        case ipv4, ipv6, disabled
        case siteToSite = "site_to_site"
    }
}
