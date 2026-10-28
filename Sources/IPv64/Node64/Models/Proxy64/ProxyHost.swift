import Foundation

extension Node64 {
    /// Kind of a proxy host.
    public struct ProxyHostKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Reverse proxy to a target.
        public static let proxy: Self = "proxy"
        /// Redirect to another address.
        public static let redirect: Self = "redirect"
        /// Answers with 404.
        public static let dead: Self = "dead"
        /// Passes TLS through without terminating it.
        public static let passthrough: Self = "passthrough"
        /// Serves a status page of the Healthchecks module.
        public static let status: Self = "status"
    }

    /// URL scheme of a proxy target (`http` or `https`).
    public struct ProxyHostScheme: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let http: Self = "http"
        public static let https: Self = "https"
    }

    /// Minimum TLS version of a proxy host.
    public struct ProxyHostMinTLS: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let tls12: Self = "1.2"
        public static let tls13: Self = "1.3"
    }

    /// Scheme of a redirect target.
    public struct ProxyHostRedirectScheme: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Keep the scheme of the request.
        public static let auto: Self = "auto"
        public static let http: Self = "http"
        public static let https: Self = "https"
    }

    /// Reachability state of a target.
    public struct ProxyHostReachState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let unknown: Self = "unknown"
        public static let up: Self = "up"
        public static let slow: Self = "slow"
        public static let down: Self = "down"
    }

    /// State of the certificate used by a host.
    public struct ProxyHostCertificateState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// HTTP only, no certificate needed.
        public static let http: Self = "http"
        public static let ok: Self = "ok"
        /// Expires soon.
        public static let soon: Self = "soon"
        public static let expired: Self = "expired"
        /// No matching certificate.
        public static let missing: Self = "missing"
    }

    /// Result of creating a DNS record for a host name.
    public struct ProxyHostDNSRecordResult: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let created: Self = "created"
        public static let exists: Self = "exists"
        public static let notIPv64: Self = "not_ipv64"
        public static let apexCNAME: Self = "apex_cname"
        public static let error: Self = "error"
    }

    /// DNS record type for `create_dns_record`.
    public struct ProxyHostDNSRecordType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let cname: Self = "CNAME"
        public static let a: Self = "A"
        public static let aaaa: Self = "AAAA"
    }

    /// Source of a certificate requested together with a host.
    public struct ProxyHostCertificateSource: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let auto: Self = "auto"
        public static let ipv64: Self = "ipv64"
        public static let alias: Self = "alias"
        public static let http: Self = "http"
        public static let dns: Self = "dns"
    }

    /// Country filter mode (`geo_mode`) of hosts and streams.
    public struct CDNGeoMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Country filter off (empty string).
        public static let off: Self = ""
        /// Block the listed countries.
        public static let block: Self = "block"
        /// Allow only the listed countries.
        public static let allow: Self = "allow"
    }

    /// A header name/value pair.
    public struct CDNHeader: Codable, Hashable, Sendable {
        /// Header name.
        public var name: String?
        /// Header value.
        public var value: String?

        /// Creates an instance; pass only the fields you want to set.
        public init(name: String? = nil, value: String? = nil) {
            self.name = name
            self.value = value
        }
    }

    /// A path-specific target of a proxy host. Schema `CDNLocation`.
    public struct CDNLocation: Codable, Hashable, Sendable {
        /// Path prefix.
        public var path: String?
        /// Scheme of the target.
        public var scheme: ProxyHostScheme?
        /// Target name or IP.
        public var targetHost: String?
        /// Target port.
        public var targetPort: Int?
        /// Replaces the path at the target.
        public var forwardPath: String?
        /// Whether WebSockets are passed.
        public var websockets: Bool?
        /// Access list ID; `0` = same as the host.
        public var accessListID: Int?

        /// Creates an instance; pass only the fields you want to set.
        public init(
            path: String? = nil,
            scheme: ProxyHostScheme? = nil,
            targetHost: String? = nil,
            targetPort: Int? = nil,
            forwardPath: String? = nil,
            websockets: Bool? = nil,
            accessListID: Int? = nil
        ) {
            self.path = path
            self.scheme = scheme
            self.targetHost = targetHost
            self.targetPort = targetPort
            self.forwardPath = forwardPath
            self.websockets = websockets
            self.accessListID = accessListID
        }

        enum CodingKeys: String, CodingKey {
            case path, scheme
            case targetHost = "target_host"
            case targetPort = "target_port"
            case forwardPath = "forward_path"
            case websockets
            case accessListID = "access_list_id"
        }
    }

    /// Advanced settings of a proxy host. Schema `CDNAdvanced`.
    public struct CDNAdvanced: Codable, Hashable, Sendable {
        /// Headers added to the request.
        public var requestHeaders: [CDNHeader]?
        /// Request headers to remove.
        public var requestRemove: [String]?
        /// Headers added to the response.
        public var responseHeaders: [CDNHeader]?
        /// Response headers to remove.
        public var responseRemove: [String]?
        /// `""` = name of the visitor, `"target"` = target, otherwise a fixed value.
        public var hostHeader: String?
        /// Timeout towards the target in seconds.
        public var timeoutSeconds: Int?
        /// Maximum request body size in MB.
        public var maxBodyMB: Int?
        /// Disable response buffering.
        public var noBuffering: Bool?
        /// Compress responses with gzip.
        public var gzip: Bool?
        /// Trusted proxy addresses or networks.
        public var trustedProxies: [String]?
        /// Write an access log.
        public var accessLog: Bool?
        /// Disables the per-IP request limit and per-target limit (connection limits and bans still apply).
        public var noLimits: Bool?
        /// Country filter mode.
        public var geoMode: CDNGeoMode?
        /// ISO country codes, at most 60 (e.g. `["DE", "AT"]`).
        public var geoCountries: [String]?
        /// Reject AI bots (403) by user agent. Proxy, redirect and status hosts only.
        public var aiBots: Bool?
        /// Let requests made on behalf of a user pass the AI bot filter.
        public var aiBotsAllowUser: Bool?
        /// Serve a `/robots.txt` disallowing all AI bots when the target has none. Proxy hosts only.
        public var aiRobots: Bool?

        /// Creates an instance; pass only the fields you want to set.
        public init(
            requestHeaders: [CDNHeader]? = nil,
            requestRemove: [String]? = nil,
            responseHeaders: [CDNHeader]? = nil,
            responseRemove: [String]? = nil,
            hostHeader: String? = nil,
            timeoutSeconds: Int? = nil,
            maxBodyMB: Int? = nil,
            noBuffering: Bool? = nil,
            gzip: Bool? = nil,
            trustedProxies: [String]? = nil,
            accessLog: Bool? = nil,
            noLimits: Bool? = nil,
            geoMode: CDNGeoMode? = nil,
            geoCountries: [String]? = nil,
            aiBots: Bool? = nil,
            aiBotsAllowUser: Bool? = nil,
            aiRobots: Bool? = nil
        ) {
            self.requestHeaders = requestHeaders
            self.requestRemove = requestRemove
            self.responseHeaders = responseHeaders
            self.responseRemove = responseRemove
            self.hostHeader = hostHeader
            self.timeoutSeconds = timeoutSeconds
            self.maxBodyMB = maxBodyMB
            self.noBuffering = noBuffering
            self.gzip = gzip
            self.trustedProxies = trustedProxies
            self.accessLog = accessLog
            self.noLimits = noLimits
            self.geoMode = geoMode
            self.geoCountries = geoCountries
            self.aiBots = aiBots
            self.aiBotsAllowUser = aiBotsAllowUser
            self.aiRobots = aiRobots
        }

        enum CodingKeys: String, CodingKey {
            case requestHeaders = "request_headers"
            case requestRemove = "request_remove"
            case responseHeaders = "response_headers"
            case responseRemove = "response_remove"
            case hostHeader = "host_header"
            case timeoutSeconds = "timeout_seconds"
            case maxBodyMB = "max_body_mb"
            case noBuffering = "no_buffering"
            case gzip
            case trustedProxies = "trusted_proxies"
            case accessLog = "access_log"
            case noLimits = "no_limits"
            case geoMode = "geo_mode"
            case geoCountries = "geo_countries"
            case aiBots = "ai_bots"
            case aiBotsAllowUser = "ai_bots_allow_user"
            case aiRobots = "ai_robots"
        }
    }

    /// A health check that watches the target of a host. Schema `CDNHostWatch`.
    public struct CDNHostWatch: Codable, Hashable, Sendable {
        /// Token of the health check.
        public let token: String?
        /// Name of the health check.
        public let name: String?
        /// Type of the health check.
        public let type: String?
        /// `up`, `down`, `new` …
        public let state: String?
        /// Whether the check is paused.
        public let paused: Bool?
        /// Runs on this node (not on ipv64.net or another node).
        public let local: Bool?
        /// Ping: only the host matches.
        public let hostOnly: Bool?
        /// Time of the last check.
        public let lastCheck: Date?

        enum CodingKeys: String, CodingKey {
            case token, name, type, state, paused, local
            case hostOnly = "host_only"
            case lastCheck = "last_check"
        }
    }

    /// Reachability of the target of a host.
    public struct ProxyHostReach: Codable, Hashable, Sendable {
        /// Reachability state.
        public let state: ProxyHostReachState?
        /// Response time in milliseconds.
        public let ms: Int?
        /// Error message of the last check.
        public let error: String?
        /// Time of the last check.
        public let checkedAt: Date?
        /// Since when the state holds.
        public let since: Date?

        enum CodingKeys: String, CodingKey {
            case state, ms, error
            case checkedAt = "checked_at"
            case since
        }
    }

    /// Request counters of a host since the module started.
    public struct ProxyHostStats: Codable, Hashable, Sendable {
        /// Requests since the module started.
        public let requests: Int?
        /// Failed requests since the module started.
        public let errors: Int?
        /// Rejected requests since the module started.
        public let blocked: Int?
    }

    /// Certificate summary of a host.
    public struct ProxyHostCertificate: Codable, Hashable, Sendable {
        /// Certificate state.
        public let state: ProxyHostCertificateState?
        /// Name of the certificate.
        public let name: String?
        /// Days until the certificate expires.
        public let daysLeft: Int?
        /// Name without a matching certificate.
        public let missing: String?

        enum CodingKeys: String, CodingKey {
            case state, name
            case daysLeft = "days_left"
            case missing
        }
    }

    /// Result of creating a DNS record for one host name.
    public struct ProxyHostDNSRecord: Codable, Hashable, Sendable {
        /// Host name.
        public let name: String?
        /// Outcome for the name.
        public let result: ProxyHostDNSRecordResult?
        /// Error message.
        public let error: String?
    }

    /// A PROXY64 host. Schema `ProxyHost`.
    public struct ProxyHost: Codable, Hashable, Sendable, Identifiable {
        /// Host ID.
        public let id: Int
        /// Kind of the host.
        public let kind: ProxyHostKind?
        /// Domain names, also `*.domain`.
        public let names: [String]?
        /// Whether the host is enabled.
        public let enabled: Bool?
        /// Scheme of the target.
        public let scheme: ProxyHostScheme?
        /// Target name or IP.
        public let targetHost: String?
        /// Target port.
        public let targetPort: Int?
        /// Whether WebSockets are passed.
        public let websockets: Bool?
        /// Block common exploit requests.
        public let blockExploits: Bool?
        /// Cache static assets.
        public let cacheAssets: Bool?
        /// `0` = matching certificate by name, `-1` = HTTP only, otherwise a certificate ID.
        public let certID: Int?
        /// Redirect HTTP to HTTPS.
        public let forceSSL: Bool?
        /// Enable HTTP/2.
        public let http2: Bool?
        /// Enable HTTP/3.
        public let http3: Bool?
        /// Send the HSTS header.
        public let hsts: Bool?
        /// Include subdomains in HSTS.
        public let hstsSubdomains: Bool?
        /// Minimum TLS version.
        public let minTLS: ProxyHostMinTLS?
        /// Verify the certificate of an https target.
        public let verifyTarget: Bool?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last update.
        public let updatedAt: Date?
        /// Reachability of the target.
        public let reach: ProxyHostReach?
        /// Counters since the module started.
        public let stats: ProxyHostStats?
        /// Certificate summary.
        public let certificate: ProxyHostCertificate?
        /// The name belongs to another part (e.g. DNS64).
        public let routeError: String?
        /// Set after `request_certificate` failed.
        public let certificateError: String?
        /// Redirect target `domain[:port][/path]`.
        public let redirectTarget: String?
        /// Scheme of the redirect target.
        public let redirectScheme: ProxyHostRedirectScheme?
        /// One of 300, 301, 302, 303, 307, 308.
        public let redirectCode: Int?
        /// Append the requested path to the redirect target.
        public let preservePath: Bool?
        /// `0` = public.
        public let accessListID: Int?
        /// Path-specific targets.
        public let locations: [CDNLocation]?
        /// Advanced settings.
        public let advanced: CDNAdvanced?
        /// Only after `create_dns_record`.
        public let dnsRecords: [ProxyHostDNSRecord]?
        /// Why creating the DNS records failed.
        public let dnsError: String?
        /// Health checks on this target (only if the Healthchecks module runs).
        public let healthchecks: [CDNHostWatch]?
        /// Status page ID for kind `status`, otherwise `0`.
        public let statusPageID: Int?

        enum CodingKeys: String, CodingKey {
            case id, kind, names, enabled, scheme
            case targetHost = "target_host"
            case targetPort = "target_port"
            case websockets
            case blockExploits = "block_exploits"
            case cacheAssets = "cache_assets"
            case certID = "cert_id"
            case forceSSL = "force_ssl"
            case http2, http3, hsts
            case hstsSubdomains = "hsts_subdomains"
            case minTLS = "min_tls"
            case verifyTarget = "verify_target"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case reach, stats, certificate
            case routeError = "route_error"
            case certificateError = "certificate_error"
            case redirectTarget = "redirect_target"
            case redirectScheme = "redirect_scheme"
            case redirectCode = "redirect_code"
            case preservePath = "preserve_path"
            case accessListID = "access_list_id"
            case locations, advanced
            case dnsRecords = "dns_records"
            case dnsError = "dns_error"
            case healthchecks
            case statusPageID = "status_page_id"
        }
    }

    /// Certificate request sent together with a host (`request_certificate`).
    public struct ProxyHostCertificateRequest: Codable, Hashable, Sendable {
        /// Where the certificate comes from.
        public var source: ProxyHostCertificateSource?
        /// Alias zone for DNS validation.
        public var aliasZone: String?
        /// Alias prefix for DNS validation.
        public var aliasPrefix: String?
        /// Use the staging environment of the certificate authority.
        public var staging: Bool?
        /// ID of the DNS account used for validation.
        public var dnsAccount: Int?

        /// Creates an instance; pass only the fields you want to set.
        public init(
            source: ProxyHostCertificateSource? = nil,
            aliasZone: String? = nil,
            aliasPrefix: String? = nil,
            staging: Bool? = nil,
            dnsAccount: Int? = nil
        ) {
            self.source = source
            self.aliasZone = aliasZone
            self.aliasPrefix = aliasPrefix
            self.staging = staging
            self.dnsAccount = dnsAccount
        }

        enum CodingKeys: String, CodingKey {
            case source
            case aliasZone = "alias_zone"
            case aliasPrefix = "alias_prefix"
            case staging
            case dnsAccount = "dns_account"
        }
    }

    /// Request to create a DNS record for every host name (`create_dns_record`).
    public struct ProxyHostDNSRecordRequest: Codable, Hashable, Sendable {
        /// Type.
        public var type: ProxyHostDNSRecordType?
        /// Target domain or IP.
        public var content: String?

        /// Creates an instance; pass only the fields you want to set.
        public init(type: ProxyHostDNSRecordType? = nil, content: String? = nil) {
            self.type = type
            self.content = content
        }
    }

    /// Writable fields of a host. Schema `ProxyHostInput`.
    ///
    /// When creating, missing fields get defaults (enabled, http, port 80, WebSockets, HTTP/2,
    /// HTTP/3, TLS 1.2); when updating, they stay unchanged.
    public struct ProxyHostInput: Encodable, Hashable, Sendable {
        /// Kind; only when creating, default `proxy`.
        public var kind: ProxyHostKind?
        /// Domain names, also `*.domain`.
        public var names: [String]?
        /// Whether it is enabled.
        public var enabled: Bool?
        /// Scheme of the target.
        public var scheme: ProxyHostScheme?
        /// Target name or IP.
        public var targetHost: String?
        /// Target port.
        public var targetPort: Int?
        /// Whether WebSockets are passed.
        public var websockets: Bool?
        /// Block common exploit requests.
        public var blockExploits: Bool?
        /// Cache static assets.
        public var cacheAssets: Bool?
        /// `0` = matching certificate by name, `-1` = HTTP only, otherwise a certificate ID.
        public var certID: Int?
        /// Redirect HTTP to HTTPS.
        public var forceSSL: Bool?
        /// Enable HTTP/2.
        public var http2: Bool?
        /// Enable HTTP/3.
        public var http3: Bool?
        /// Send the HSTS header.
        public var hsts: Bool?
        /// Include subdomains in HSTS.
        public var hstsSubdomains: Bool?
        /// Minimum TLS version.
        public var minTLS: ProxyHostMinTLS?
        /// Verify the certificate of an https target (default off).
        public var verifyTarget: Bool?
        /// Request a certificate for all domains in the background; a failure shows up as `certificateError`.
        public var requestCertificate: ProxyHostCertificateRequest?
        /// Redirect target `domain[:port][/path]`.
        public var redirectTarget: String?
        /// Scheme of the redirect target.
        public var redirectScheme: ProxyHostRedirectScheme?
        /// One of 300, 301, 302, 303, 307, 308.
        public var redirectCode: Int?
        /// Append the requested path to the redirect target.
        public var preservePath: Bool?
        /// `0` = public.
        public var accessListID: Int?
        /// Path-specific targets.
        public var locations: [CDNLocation]?
        /// Advanced settings.
        public var advanced: CDNAdvanced?
        /// Create a DNS record in the ipv64 account for every domain (existing ones stay).
        public var createDNSRecord: ProxyHostDNSRecordRequest?
        /// Status page ID (required, > 0, for kind `status`).
        public var statusPageID: Int?

        /// Creates a host input; pass only the fields you want to set.
        public init(
            kind: ProxyHostKind? = nil,
            names: [String]? = nil,
            enabled: Bool? = nil,
            scheme: ProxyHostScheme? = nil,
            targetHost: String? = nil,
            targetPort: Int? = nil,
            websockets: Bool? = nil,
            blockExploits: Bool? = nil,
            cacheAssets: Bool? = nil,
            certID: Int? = nil,
            forceSSL: Bool? = nil,
            http2: Bool? = nil,
            http3: Bool? = nil,
            hsts: Bool? = nil,
            hstsSubdomains: Bool? = nil,
            minTLS: ProxyHostMinTLS? = nil,
            verifyTarget: Bool? = nil,
            requestCertificate: ProxyHostCertificateRequest? = nil,
            redirectTarget: String? = nil,
            redirectScheme: ProxyHostRedirectScheme? = nil,
            redirectCode: Int? = nil,
            preservePath: Bool? = nil,
            accessListID: Int? = nil,
            locations: [CDNLocation]? = nil,
            advanced: CDNAdvanced? = nil,
            createDNSRecord: ProxyHostDNSRecordRequest? = nil,
            statusPageID: Int? = nil
        ) {
            self.kind = kind
            self.names = names
            self.enabled = enabled
            self.scheme = scheme
            self.targetHost = targetHost
            self.targetPort = targetPort
            self.websockets = websockets
            self.blockExploits = blockExploits
            self.cacheAssets = cacheAssets
            self.certID = certID
            self.forceSSL = forceSSL
            self.http2 = http2
            self.http3 = http3
            self.hsts = hsts
            self.hstsSubdomains = hstsSubdomains
            self.minTLS = minTLS
            self.verifyTarget = verifyTarget
            self.requestCertificate = requestCertificate
            self.redirectTarget = redirectTarget
            self.redirectScheme = redirectScheme
            self.redirectCode = redirectCode
            self.preservePath = preservePath
            self.accessListID = accessListID
            self.locations = locations
            self.advanced = advanced
            self.createDNSRecord = createDNSRecord
            self.statusPageID = statusPageID
        }

        enum CodingKeys: String, CodingKey {
            case kind, names, enabled, scheme
            case targetHost = "target_host"
            case targetPort = "target_port"
            case websockets
            case blockExploits = "block_exploits"
            case cacheAssets = "cache_assets"
            case certID = "cert_id"
            case forceSSL = "force_ssl"
            case http2, http3, hsts
            case hstsSubdomains = "hsts_subdomains"
            case minTLS = "min_tls"
            case verifyTarget = "verify_target"
            case requestCertificate = "request_certificate"
            case redirectTarget = "redirect_target"
            case redirectScheme = "redirect_scheme"
            case redirectCode = "redirect_code"
            case preservePath = "preserve_path"
            case accessListID = "access_list_id"
            case locations, advanced
            case createDNSRecord = "create_dns_record"
            case statusPageID = "status_page_id"
        }
    }
}
