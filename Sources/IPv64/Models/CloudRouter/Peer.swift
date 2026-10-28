import Foundation

/// A WireGuard peer of a ``Gateway``.
public struct Peer: Codable, Hashable, Sendable, Identifiable {
    /// Peer ID (32 characters, also usable as token).
    public let id: String
    /// Name.
    public let name: String?
    /// Provisioning state; `ready` means the change was applied.
    public let state: CloudRouterState?
    /// Peer is disabled.
    public let disabled: Bool?
    /// Marked as site-to-site peer.
    public let siteToSite: Bool?
    /// Tunnel IPv4 address (CIDR).
    public let ipv4: String?
    /// Tunnel IPv6 address (CIDR).
    public let ipv6: String?
    /// DNS server written into the client config.
    public let dnsServer: String?
    /// Fixed endpoint of the peer (IP or hostname).
    public let endpoint: String?
    /// Port of the fixed endpoint.
    public let endpointPort: Int?
    /// Keepalive as `hh:mm:ss`, e.g. `00:00:25`.
    public let keepalive: String?
    /// Public key (Base64).
    public let publicKey: String?
    /// A preshared key is set.
    public let hasPresharedKey: Bool?
    /// Last seen address, e.g. `198.51.100.7:51820`.
    public let currentEndpoint: String?
    /// Time of the last handshake (as sent by the server).
    public let lastHandshake: String?
    /// Transferred bytes.
    public let trafficBytes: TrafficBytes?
    /// Additional networks in the client config.
    public let allowedIPs: [AllowedIP]?

    /// Incoming and outgoing traffic of a peer.
    public struct TrafficBytes: Codable, Hashable, Sendable {
        /// Incoming bytes.
        public let `in`: Double?
        /// Outgoing bytes.
        public let out: Double?
    }

    /// An entry of the peer's AllowedIPs.
    public struct AllowedIP: Codable, Hashable, Sendable, Identifiable {
        /// ID, used to remove the entry.
        public let id: Int?
        /// IP or network in CIDR notation.
        public let network: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, name, state, disabled
        case siteToSite = "site_to_site"
        case ipv4, ipv6
        case dnsServer = "dns_server"
        case endpoint
        case endpointPort = "endpoint_port"
        case keepalive
        case publicKey = "public_key"
        case hasPresharedKey = "has_preshared_key"
        case currentEndpoint = "current_endpoint"
        case lastHandshake = "last_handshake"
        case trafficBytes = "traffic_bytes"
        case allowedIPs = "allowed_ips"
    }
}
