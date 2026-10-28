import Foundation

extension Node64 {
    /// Transport of a tunnel connection to an edge server.
    public struct CDNOnlineTransport: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let quic: Self = "quic"
        public static let tcp: Self = "tcp"
        /// Not connected (empty string).
        public static let none: Self = ""
    }

    /// Outcome of switching on one name.
    public struct CDNOnlineResultState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let on: Self = "on"
        public static let skipped: Self = "skipped"
        public static let error: Self = "error"
    }

    /// Address family of a test probe.
    public struct CDNOnlineFamily: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let ipv4: Self = "ipv4"
        public static let ipv6: Self = "ipv6"
    }

    /// Connection to an edge server.
    public struct CDNOnlineEdge: Codable, Hashable, Sendable {
        /// Name of the edge server.
        public let name: String?
        /// Host name.
        public let host: String?
        /// Whether the edge connection is up.
        public let connected: Bool?
        /// Transport used for the connection.
        public let transport: CDNOnlineTransport?
        /// Streams since the start.
        public let total: Int?
    }

    /// A name switched on at CDN64.
    public struct CDNOnlineName: Codable, Hashable, Sendable {
        /// Switched-on name.
        public let name: String?
        /// ID of the host.
        public let hostID: Int?
        /// ID of the name at ipv64.
        public let remoteID: Int?
        /// Mode the name was switched on with.
        public let mode: Int?
        /// Health check created when switching on.
        public let check: String?
        /// Creation time.
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case name
            case hostID = "host_id"
            case remoteID = "remote_id"
            case mode, check
            case createdAt = "created_at"
        }
    }

    /// Domain quota at ipv64 (old and new CDN together).
    public struct CDNOnlineDomainQuota: Codable, Hashable, Sendable {
        /// Domains in use.
        public let used: Int?
        /// Domains in use at the old CDN.
        public let oldCDN: Int?
        /// Domain limit.
        public let limit: Int?

        enum CodingKeys: String, CodingKey {
            case used
            case oldCDN = "old_cdn"
            case limit
        }
    }

    /// Traffic quota at ipv64 in MB (old and new CDN together).
    public struct CDNOnlineTrafficQuota: Codable, Hashable, Sendable {
        /// Traffic used in MB.
        public let used: Double?
        /// Traffic used at the old CDN in MB.
        public let oldCDN: Double?
        /// Traffic limit in MB.
        public let limit: Int?

        enum CodingKeys: String, CodingKey {
            case used
            case oldCDN = "old_cdn"
            case limit
        }
    }

    /// Quota at ipv64 (old and new CDN together).
    public struct CDNOnlineQuota: Codable, Hashable, Sendable {
        /// Domain quota.
        public let domains: CDNOnlineDomainQuota?
        /// Traffic quota in MB.
        public let trafficMB: CDNOnlineTrafficQuota?
        /// `0` = unlimited.
        public let bandwidthMbit: Int?

        enum CodingKeys: String, CodingKey {
            case domains
            case trafficMB = "traffic_mb"
            case bandwidthMbit = "bandwidth_mbit"
        }
    }

    /// State of the CDN64 online connection. Schema `CDNOnlineStatus`.
    public struct CDNOnlineStatus: Codable, Hashable, Sendable {
        /// A tunnel is set up.
        public let configured: Bool?
        /// Tunnel ID at ipv64 (`tn_...`).
        public let tunnel: String?
        /// Connections to the edge servers.
        public let edges: [CDNOnlineEdge]?
        /// An ipv64 account is linked (central API key).
        public let apiReady: Bool?
        /// Names switched on at CDN64.
        public let names: [CDNOnlineName]?
        /// Quota at ipv64.
        public let quota: CDNOnlineQuota?
        /// Last sync with ipv64.
        public let synced: Date?
        /// Error of the last sync with ipv64, if any.
        public let syncError: String?
        /// `net.core.rmem_max` of the host.
        public let udpBuffer: Int?
        /// Too small for full QUIC speed.
        public let udpBufferLow: Bool?

        enum CodingKeys: String, CodingKey {
            case configured, tunnel, edges
            case apiReady = "api_ready"
            case names, quota, synced
            case syncError = "sync_error"
            case udpBuffer = "udp_buffer"
            case udpBufferLow = "udp_buffer_low"
        }
    }

    /// Result for one name when switching on. Schema `CDNOnlineResult`.
    public struct CDNOnlineResult: Codable, Hashable, Sendable {
        /// Name that was switched on.
        public let name: String?
        /// Outcome for the name.
        public let result: CDNOnlineResultState?
        /// Error code from ipv64 (e.g. `domain_not_in_account`, `cname_exists`, `limit_reached`) or `wildcard_name`.
        public let code: String?
        /// Error message.
        public let error: String?
        /// Further explanation.
        public let text: String?
    }

    /// One probe of the online self-test.
    public struct CDNOnlineProbe: Codable, Hashable, Sendable {
        /// Name of the edge server.
        public let edge: String?
        /// Probed address.
        public let addr: String?
        /// Address family of the probe.
        public let family: CDNOnlineFamily?
        /// The probe arrived through the tunnel of this node.
        public let ok: Bool?
        /// The node lacks this address family.
        public let skipped: Bool?
        /// Round-trip time in milliseconds.
        public let ms: Int?
        /// Certificate valid for visitors (TLS only).
        public let trusted: Bool?
        /// Error message of the probe.
        public let error: String?
    }

    /// Self-test result for one name. Schema `CDNOnlineTest`.
    public struct CDNOnlineTest: Codable, Hashable, Sendable {
        /// Tested name.
        public let name: String?
        /// Whether the name is served with TLS.
        public let tls: Bool?
        /// Probes per edge server and address family.
        public let probes: [CDNOnlineProbe]?
        /// Answer of a public resolver.
        public let dns: [String]?
        /// Whether the public DNS answer points to the edge servers.
        public let dnsOK: Bool?

        enum CodingKeys: String, CodingKey {
            case name, tls, probes, dns
            case dnsOK = "dns_ok"
        }
    }

    /// Response of switching on the names of a host.
    public struct CDNOnlineEnableResult: Codable, Hashable, Sendable {
        /// One result per name.
        public let results: [CDNOnlineResult]?
        /// Token of the online health check, if requested.
        public let check: String?
        /// Why creating the health check failed.
        public let checkError: String?

        enum CodingKeys: String, CodingKey {
            case results, check
            case checkError = "check_error"
        }
    }

    /// An edge server entry for setting the tunnel by hand.
    public struct CDNOnlineEdgeInput: Encodable, Hashable, Sendable {
        /// Name of the edge server.
        public var name: String?
        /// Host name of the edge server.
        public var host: String?
        /// Port of the edge server.
        public var port: Int?
        /// IP addresses of the edge server.
        public var ips: [String]?

        /// Creates an instance; pass only the fields you want to set.
        public init(name: String? = nil, host: String? = nil, port: Int? = nil, ips: [String]? = nil) {
            self.name = name
            self.host = host
            self.port = port
            self.ips = ips
        }
    }

    /// Tunnel data for setting the tunnel by hand (`PUT /cdn64/online`).
    public struct CDNOnlineTunnelInput: Encodable, Hashable, Sendable {
        /// Tunnel ID at ipv64 (`tn_...`).
        public var tunnel: String?
        /// Empty = unchanged.
        public var token: String?
        /// Edge servers of the tunnel.
        public var edges: [CDNOnlineEdgeInput]?

        /// Creates an instance; pass only the fields you want to set.
        public init(tunnel: String? = nil, token: String? = nil, edges: [CDNOnlineEdgeInput]? = nil) {
            self.tunnel = tunnel
            self.token = token
            self.edges = edges
        }
    }
}
