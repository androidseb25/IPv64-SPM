import Foundation

/// A WireGuard gateway of a ``CloudRouter``.
public struct Gateway: Codable, Hashable, Sendable, Identifiable {
    /// Gateway ID (32 characters, also usable as token).
    public let id: String
    /// Name.
    public let name: String?
    /// Provisioning state; `ready` means the change was applied.
    public let state: CloudRouterState?
    /// Gateway is disabled.
    public let disabled: Bool?
    /// Blocked because the traffic limit was reached.
    public let trafficLimited: Bool?
    /// VPN server hosting the gateway.
    public let server: Server?
    /// WireGuard port on the server.
    public let listenPort: Int?
    /// Gateway IPv4 address (CIDR).
    public let ipv4: String?
    /// Gateway IPv6 address (CIDR).
    public let ipv6: String?
    /// Public key (Base64).
    public let publicKey: String?
    /// OSPF settings.
    public let ospf: OSPF?
    /// Transferred bytes.
    public let trafficBytes: TrafficBytes?
    /// Creation time.
    public let createdAt: Date?
    /// Peers of this gateway.
    public let peers: [Peer]?

    /// VPN server hosting a gateway.
    public struct Server: Codable, Hashable, Sendable {
        /// Server name, e.g. `VPN-FSN-1`.
        public let name: String?
        /// Hostname, e.g. `vpn1.ipv64.net`.
        public let hostname: String?
        /// Location, e.g. `Falkenstein`.
        public let location: String?
    }

    /// OSPF settings of a gateway.
    public struct OSPF: Codable, Hashable, Sendable {
        /// Area, e.g. `0.0.0.0`.
        public let areaID: String?
        /// OSPF version.
        public let version: Int?
        /// Link cost.
        public let cost: Int?

        enum CodingKeys: String, CodingKey {
            case areaID = "area_id"
            case version = "ospf_version"
            case cost
        }
    }

    /// Incoming and outgoing traffic of a gateway.
    public struct TrafficBytes: Codable, Hashable, Sendable {
        /// Incoming bytes.
        public let `in`: Double?
        /// Outgoing bytes.
        public let out: Double?
    }

    enum CodingKeys: String, CodingKey {
        case id, name, state, disabled
        case trafficLimited = "traffic_limited"
        case server
        case listenPort = "listen_port"
        case ipv4, ipv6
        case publicKey = "public_key"
        case ospf
        case trafficBytes = "traffic_bytes"
        case createdAt = "created_at"
        case peers
    }
}
