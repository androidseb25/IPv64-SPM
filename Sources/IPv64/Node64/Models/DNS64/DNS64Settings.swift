import Foundation

extension Node64 {
    /// How several upstream servers are used.
    public struct DNS64UpstreamMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Ask the fastest servers (see `upstreamCount`).
        public static let fastest: Self = "fastest"
        /// Ask all servers at once.
        public static let parallel: Self = "parallel"
        /// Ask in the configured order.
        public static let ordered: Self = "ordered"
    }

    /// Answer for blocked domains.
    public struct DNS64BlockMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Answer with `0.0.0.0` / `::`.
        public static let zero: Self = "zero"
        /// Answer with NXDOMAIN.
        public static let nxdomain: Self = "nxdomain"
    }

    /// How client addresses are stored in the log.
    public struct DNS64Anonymization: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Store full addresses.
        public static let off: Self = "off"
        /// Mask the host part.
        public static let mask: Self = "mask"
        /// Do not store clients.
        public static let hide: Self = "hide"
    }

    /// Source of the certificate for encrypted DNS.
    public struct DNS64CertMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Own home-network CA.
        public static let selfSigned: Self = "self"
        /// Certificate of the web interface.
        public static let node64: Self = "node64"
        /// Let's Encrypt.
        public static let acme: Self = "acme"
        /// Certificate from the certificate management (see `certID`).
        public static let central: Self = "central"
    }

    /// A blocklist entry of the settings. Schema `DNS64List`.
    public struct DNS64List: Codable, Hashable, Sendable {
        /// Display name.
        public var name: String?
        /// Download URL.
        public var url: String?
        /// Whether the list is active.
        public var enabled: Bool?
        /// `true` for lists added by the user.
        public var custom: Bool?

        /// Creates a blocklist entry for ``DNS64SettingsInput/lists``.
        public init(name: String? = nil, url: String? = nil, enabled: Bool? = nil, custom: Bool? = nil) {
            self.name = name
            self.url = url
            self.enabled = enabled
            self.custom = custom
        }
    }

    /// An upstream server entry of the settings. Schema `DNS64Upstream`.
    public struct DNS64Upstream: Codable, Hashable, Sendable {
        /// Display name.
        public var name: String?
        /// `https://…` (DoH), `tls://name[:853]` (DoT) or `quic://name[:853]` (DoQ).
        public var url: String?
        /// Bootstrap IP addresses.
        public var ips: [String]?
        /// Whether the server is used.
        public var enabled: Bool?
        /// `true` for servers added by the user.
        public var custom: Bool?

        /// Creates an upstream entry for ``DNS64SettingsInput/upstreams``.
        public init(
            name: String? = nil,
            url: String? = nil,
            ips: [String]? = nil,
            enabled: Bool? = nil,
            custom: Bool? = nil
        ) {
            self.name = name
            self.url = url
            self.ips = ips
            self.enabled = enabled
            self.custom = custom
        }
    }

    /// Settings of the DNS64 resolver. Schema `DNS64Settings`.
    ///
    /// To change settings use ``DNS64SettingsInput``.
    public struct DNS64Settings: Codable, Hashable, Sendable {
        /// DNS port.
        public let port: Int?
        /// Bind address.
        public let bind: String?
        /// DNS server for local names.
        public let router: String?
        /// Days the query log is kept.
        public let retentionDays: Int?
        /// How upstream servers are used.
        public let upstreamMode: DNS64UpstreamMode?
        /// Upstream servers.
        public let upstreams: [DNS64Upstream]?
        /// Blocklists.
        public let lists: [DNS64List]?
        /// Hours between blocklist updates.
        public let listHours: Int?
        /// Answer for blocked domains.
        public let blockMode: DNS64BlockMode?
        /// Maximum number of cache entries.
        public let cacheSize: Int?
        /// Log anonymization.
        public let anonymize: DNS64Anonymization?
        /// Networks allowed to use the resolver.
        public let allowNets: [String]?
        /// DNS over HTTPS enabled.
        public let doh: Bool?
        /// DNS over TLS enabled.
        public let dot: Bool?
        /// DNS over QUIC enabled.
        public let doq: Bool?
        /// DoH port (443).
        public let dohPort: Int?
        /// DoT (TCP) and DoQ (UDP) port (853).
        public let dotPort: Int?
        /// Names of the node for devices and the certificate.
        public let names: [String]?
        /// Certificate source.
        public let certMode: DNS64CertMode?
        /// Notify when an upstream fails.
        public let notifyUpstream: Bool?
        /// Notify when a blocklist fails.
        public let notifyLists: Bool?
        /// ACME: ipv64 domain.
        public let acmeDomain: String?
        /// ACME: prefix.
        public let acmePrefix: String?
        /// ACME: e-mail address.
        public let acmeEmail: String?
        /// ACME: use the staging environment.
        public let acmeStaging: Bool?
        /// `fastest`: number of upstreams asked at once (1-3, default 2).
        public let upstreamCount: Int?
        /// `central`: ID of the certificate in the certificate management.
        public let certID: Int?
        /// Answer `use-application-dns.net` with NXDOMAIN so Firefox disables its own DoH (default on).
        public let firefoxCanary: Bool?

        enum CodingKeys: String, CodingKey {
            case port, bind, router
            case retentionDays = "retention_days"
            case upstreamMode = "upstream_mode"
            case upstreams, lists
            case listHours = "list_hours"
            case blockMode = "block_mode"
            case cacheSize = "cache_size"
            case anonymize
            case allowNets = "allow_nets"
            case doh, dot, doq
            case dohPort = "doh_port"
            case dotPort = "dot_port"
            case names
            case certMode = "cert_mode"
            case notifyUpstream = "notify_upstream"
            case notifyLists = "notify_lists"
            case acmeDomain = "acme_domain"
            case acmePrefix = "acme_prefix"
            case acmeEmail = "acme_email"
            case acmeStaging = "acme_staging"
            case upstreamCount = "upstream_count"
            case certID = "cert_id"
            case firefoxCanary = "firefox_canary"
        }
    }

    /// Changes for ``Node64/DNS64/updateSettings(_:)``. Only fields you set are sent.
    ///
    /// `upstreams` and `lists` replace the whole list.
    public struct DNS64SettingsInput: Encodable, Hashable, Sendable {
        /// DNS port.
        public var port: Int?
        /// Bind address.
        public var bind: String?
        /// DNS server for local names.
        public var router: String?
        /// Days the query log is kept.
        public var retentionDays: Int?
        /// How upstream servers are used.
        public var upstreamMode: DNS64UpstreamMode?
        /// Replaces the whole upstream list. Read it with ``Node64/DNS64/settings()``, modify it and send the complete list back.
        public var upstreams: [DNS64Upstream]?
        /// Replaces the whole blocklist list. Read it with ``Node64/DNS64/settings()``, modify it and send the complete list back.
        public var lists: [DNS64List]?
        /// Hours between blocklist updates.
        public var listHours: Int?
        /// Answer for blocked domains.
        public var blockMode: DNS64BlockMode?
        /// Maximum number of cache entries.
        public var cacheSize: Int?
        /// Log anonymization.
        public var anonymize: DNS64Anonymization?
        /// Networks allowed to use the resolver.
        public var allowNets: [String]?
        /// DNS over HTTPS enabled.
        public var doh: Bool?
        /// DNS over TLS enabled.
        public var dot: Bool?
        /// DNS over QUIC enabled.
        public var doq: Bool?
        /// DoH port (443).
        public var dohPort: Int?
        /// DoT (TCP) and DoQ (UDP) port (853).
        public var dotPort: Int?
        /// Names of the node for devices and the certificate.
        public var names: [String]?
        /// Certificate source.
        public var certMode: DNS64CertMode?
        /// Notify when an upstream fails.
        public var notifyUpstream: Bool?
        /// Notify when a blocklist fails.
        public var notifyLists: Bool?
        /// ACME: ipv64 domain.
        public var acmeDomain: String?
        /// ACME: prefix.
        public var acmePrefix: String?
        /// ACME: e-mail address.
        public var acmeEmail: String?
        /// ACME: use the staging environment.
        public var acmeStaging: Bool?
        /// `fastest`: number of upstreams asked at once (1-3, default 2).
        public var upstreamCount: Int?
        /// `central`: ID of the certificate in the certificate management.
        public var certID: Int?
        /// Answer `use-application-dns.net` with NXDOMAIN so Firefox disables its own DoH (default on).
        public var firefoxCanary: Bool?

        /// Creates a settings change; only fields you set are sent and changed.
        public init(
            port: Int? = nil,
            bind: String? = nil,
            router: String? = nil,
            retentionDays: Int? = nil,
            upstreamMode: DNS64UpstreamMode? = nil,
            upstreams: [DNS64Upstream]? = nil,
            lists: [DNS64List]? = nil,
            listHours: Int? = nil,
            blockMode: DNS64BlockMode? = nil,
            cacheSize: Int? = nil,
            anonymize: DNS64Anonymization? = nil,
            allowNets: [String]? = nil,
            doh: Bool? = nil,
            dot: Bool? = nil,
            doq: Bool? = nil,
            dohPort: Int? = nil,
            dotPort: Int? = nil,
            names: [String]? = nil,
            certMode: DNS64CertMode? = nil,
            notifyUpstream: Bool? = nil,
            notifyLists: Bool? = nil,
            acmeDomain: String? = nil,
            acmePrefix: String? = nil,
            acmeEmail: String? = nil,
            acmeStaging: Bool? = nil,
            upstreamCount: Int? = nil,
            certID: Int? = nil,
            firefoxCanary: Bool? = nil
        ) {
            self.port = port
            self.bind = bind
            self.router = router
            self.retentionDays = retentionDays
            self.upstreamMode = upstreamMode
            self.upstreams = upstreams
            self.lists = lists
            self.listHours = listHours
            self.blockMode = blockMode
            self.cacheSize = cacheSize
            self.anonymize = anonymize
            self.allowNets = allowNets
            self.doh = doh
            self.dot = dot
            self.doq = doq
            self.dohPort = dohPort
            self.dotPort = dotPort
            self.names = names
            self.certMode = certMode
            self.notifyUpstream = notifyUpstream
            self.notifyLists = notifyLists
            self.acmeDomain = acmeDomain
            self.acmePrefix = acmePrefix
            self.acmeEmail = acmeEmail
            self.acmeStaging = acmeStaging
            self.upstreamCount = upstreamCount
            self.certID = certID
            self.firefoxCanary = firefoxCanary
        }

        enum CodingKeys: String, CodingKey {
            case port, bind, router
            case retentionDays = "retention_days"
            case upstreamMode = "upstream_mode"
            case upstreams, lists
            case listHours = "list_hours"
            case blockMode = "block_mode"
            case cacheSize = "cache_size"
            case anonymize
            case allowNets = "allow_nets"
            case doh, dot, doq
            case dohPort = "doh_port"
            case dotPort = "dot_port"
            case names
            case certMode = "cert_mode"
            case notifyUpstream = "notify_upstream"
            case notifyLists = "notify_lists"
            case acmeDomain = "acme_domain"
            case acmePrefix = "acme_prefix"
            case acmeEmail = "acme_email"
            case acmeStaging = "acme_staging"
            case upstreamCount = "upstream_count"
            case certID = "cert_id"
            case firefoxCanary = "firefox_canary"
        }
    }
}
