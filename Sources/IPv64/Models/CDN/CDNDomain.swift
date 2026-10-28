import Foundation

/// A domain in the CDN.
///
/// Many changes are applied asynchronously (`202 Accepted`). A change is complete
/// once ``pending`` is empty; poll ``IPv64/CDN/get(_:)`` until then.
public struct CDNDomain: Codable, Hashable, Sendable, Identifiable {
    /// CDN ID (token).
    public let id: String
    /// Domain, e.g. `beispiel.ipv64.de`.
    public let domain: String?
    /// Domain ID.
    public let domainID: Int?
    /// The CDN is active.
    public let active: Bool?
    /// Open work items of the CDN bot. Empty when all changes are applied.
    public let pending: [CDNPendingTask]?
    /// At least one record is routed through the CDN.
    public let dnsRecordsEnabled: Bool?
    /// The assigned CDN server, if any.
    public let server: Server?
    /// Reverse proxy settings.
    public let proxy: Proxy?
    /// Portmapper state.
    public let portmapper: Portmapper?
    /// Traffic in megabytes.
    public let trafficMB: Traffic?
    /// Creation time.
    public let createdAt: Date?

    /// A CDN server.
    public struct Server: Codable, Hashable, Sendable {
        /// Name, e.g. `CDN-FSN-1`.
        public let name: String?
        /// Hostname, e.g. `cdn1.ipv64.net`.
        public let hostname: String?
        /// IPv4 address.
        public let ipv4: String?
        /// IPv6 address.
        public let ipv6: String?
    }

    /// Reverse proxy settings.
    public struct Proxy: Codable, Hashable, Sendable {
        /// Reverse proxy state.
        public let state: CDNProxyState?
        /// Frontend mode.
        public let frontend: CDNFrontend?
        /// Connection to your server.
        public let backend: Backend?
        /// WebSocket support.
        public let websocket: Bool?
        /// Certificate source.
        public let certificate: CDNCertificate?
        /// Cache settings.
        public let caching: Caching?
        /// Access list settings.
        public let accessList: AccessList?

        /// Connection to your server.
        public struct Backend: Codable, Hashable, Sendable {
            /// Protocol to your server.
            public let scheme: CDNBackendScheme?
            /// Port of your server.
            public let port: Int?
        }

        /// Cache settings.
        public struct Caching: Codable, Hashable, Sendable {
            /// Cache enabled.
            public let enabled: Bool?
            /// Cache duration in minutes.
            public let timeMinutes: Int?
            /// Cache size in megabytes.
            public let sizeMB: Int?

            enum CodingKeys: String, CodingKey {
                case enabled
                case timeMinutes = "time_minutes"
                case sizeMB = "size_mb"
            }
        }

        /// Access list settings.
        public struct AccessList: Codable, Hashable, Sendable {
            /// Access list enabled.
            public let enabled: Bool?
            /// Whether entries are allowed or blocked.
            public let mode: CDNAccessListMode?
        }

        enum CodingKeys: String, CodingKey {
            case state, frontend, backend, websocket, certificate, caching
            case accessList = "access_list"
        }
    }

    /// Portmapper state.
    public struct Portmapper: Codable, Hashable, Sendable {
        /// Portmapper state.
        public let state: CDNPortmapperState?
    }

    /// Traffic counters in megabytes.
    public struct Traffic: Codable, Hashable, Sendable {
        /// Incoming traffic.
        public let incoming: Double?
        /// Outgoing traffic.
        public let outgoing: Double?

        enum CodingKeys: String, CodingKey {
            case incoming = "in"
            case outgoing = "out"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, domain
        case domainID = "domain_id"
        case active, pending
        case dnsRecordsEnabled = "dns_records_enabled"
        case server, proxy, portmapper
        case trafficMB = "traffic_mb"
        case createdAt = "created_at"
    }
}

/// A CDN domain including its port mappings.
///
/// Many changes are applied asynchronously (`202 Accepted`). A change is complete
/// once ``pending`` is empty.
public struct CDNDomainDetail: Codable, Hashable, Sendable, Identifiable {
    /// CDN ID (token).
    public let id: String
    /// Domain, e.g. `beispiel.ipv64.de`.
    public let domain: String?
    /// Domain ID.
    public let domainID: Int?
    /// The CDN is active.
    public let active: Bool?
    /// Open work items of the CDN bot. Empty when all changes are applied.
    public let pending: [CDNPendingTask]?
    /// At least one record is routed through the CDN.
    public let dnsRecordsEnabled: Bool?
    /// The assigned CDN server, if any.
    public let server: CDNDomain.Server?
    /// Reverse proxy settings.
    public let proxy: CDNDomain.Proxy?
    /// Portmapper state.
    public let portmapper: CDNDomain.Portmapper?
    /// Traffic in megabytes.
    public let trafficMB: CDNDomain.Traffic?
    /// Creation time.
    public let createdAt: Date?
    /// Port mappings.
    public let mappings: [CDNMapping]?

    enum CodingKeys: String, CodingKey {
        case id, domain
        case domainID = "domain_id"
        case active, pending
        case dnsRecordsEnabled = "dns_records_enabled"
        case server, proxy, portmapper
        case trafficMB = "traffic_mb"
        case createdAt = "created_at"
        case mappings
    }
}

/// Open work item of the CDN bot.
public struct CDNPendingTask: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let serverAssignment: Self = "server_assignment"
    public static let dns: Self = "dns"
    public static let configDeploy: Self = "config_deploy"
    public static let certificate: Self = "certificate"
    public static let serverMove: Self = "server_move"
    public static let deletion: Self = "deletion"
}

/// Reverse proxy state.
public struct CDNProxyState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let off: Self = "off"
    public static let on: Self = "on"
    public static let disabling: Self = "disabling"
}

/// Frontend mode of the reverse proxy.
public struct CDNFrontend: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Plain HTTP.
    public static let http: Self = "http"
    /// HTTP is redirected to HTTPS.
    public static let httpsRedirect: Self = "https_redirect"
    /// Both HTTP and HTTPS.
    public static let httpAndHTTPS: Self = "http_and_https"
}

/// Protocol used to reach your server.
public struct CDNBackendScheme: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let http: Self = "http"
    public static let https: Self = "https"
}

/// Certificate source of the reverse proxy.
public struct CDNCertificate: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let `default`: Self = "default"
    public static let letsEncrypt: Self = "letsencrypt"
    public static let issuing: Self = "issuing"
}

/// Mode of the CDN access list.
public struct CDNAccessListMode: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Only listed entries are allowed.
    public static let allowlist: Self = "allowlist"
    /// Listed entries are blocked.
    public static let denylist: Self = "denylist"
}

/// Portmapper state.
public struct CDNPortmapperState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let off: Self = "off"
    public static let on: Self = "on"
    public static let disabling: Self = "disabling"
    /// Suspended because the traffic limit was reached.
    public static let suspendedTrafficLimit: Self = "suspended_traffic_limit"
}

/// How a record is routed through the CDN.
public struct CDNRecordMode: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// The name points completely to the CDN.
    public static let full: Self = "full"
    /// The record stays directly reachable; the CDN serves only the other address family.
    public static let otherFamilyOnly: Self = "other_family_only"
}

/// Cache settings for ``IPv64/CDN/update(_:frontend:backendScheme:backendPort:websocket:caching:accessList:)``.
public struct CDNCachingSettings: Encodable, Hashable, Sendable {
    /// Cache enabled.
    public var enabled: Bool?
    /// Cache duration in minutes (1 to 600).
    public var timeMinutes: Int?
    /// Cache size in megabytes (1 up to the plan limit).
    public var sizeMB: Int?

    public init(enabled: Bool? = nil, timeMinutes: Int? = nil, sizeMB: Int? = nil) {
        self.enabled = enabled
        self.timeMinutes = timeMinutes
        self.sizeMB = sizeMB
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case timeMinutes = "time_minutes"
        case sizeMB = "size_mb"
    }
}

/// Access list settings for ``IPv64/CDN/update(_:frontend:backendScheme:backendPort:websocket:caching:accessList:)``.
public struct CDNAccessListSettings: Encodable, Hashable, Sendable {
    /// Access list enabled.
    public var enabled: Bool?
    /// Whether entries are allowed or blocked.
    public var mode: CDNAccessListMode?

    public init(enabled: Bool? = nil, mode: CDNAccessListMode? = nil) {
        self.enabled = enabled
        self.mode = mode
    }
}
