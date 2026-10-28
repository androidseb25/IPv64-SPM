import Foundation

extension Node64 {
    /// Settings of the Honeypot64 sensor. Schema `Honeypot64Config`.
    ///
    /// Also the request body of ``Node64/Honeypot/updateSettings(_:)``. When `report` is switched on,
    /// the reported period starts now.
    public struct Honeypot64Config: Codable, Hashable, Sendable {
        /// Profile (default `standard`).
        public var profile: Honeypot64Profile?
        /// Services; only used with profile `custom`.
        public var services: [Honeypot64ServiceConfig]?
        /// Port scan detection (default `true`).
        public var scan: Bool?
        /// Concurrent connections per source IP (0 = default 8, max 1000).
        public var maxConnsPerIP: Int?
        /// Concurrent connections in total (0 = default 512, max 100000).
        public var maxConnsTotal: Int?
        /// Retention in days (1-90, default 7).
        public var retentionDays: Int?
        /// Maximum stored events (1000-5000000, default 200000).
        public var maxEvents: Int?
        /// At most one bundled message per hour for new source IPs (default `false`).
        public var notifyNew: Bool?
        /// Report to ipv64 (opt-in; needs the central ipv64 API key, otherwise 400 with `fields.report`).
        public var report: Bool?
        /// `true` = do not block detected attackers locally in PROXY64.
        public var noLocalBlock: Bool?
        /// Location of the sensor (ISO 3166-1 alpha-2); empty = automatic.
        public var country: String?
        /// Log sensor and syslog receiver.
        public var log: Honeypot64LogConfig?
        /// Certificate of the certificate management for decoy names (0 or missing = off).
        public var certID: Int?
        /// Ports that show the certificate despite a self-signed profile.
        public var certPorts: [Int]?
        /// Monitoring of the node's own login.
        public var login: Honeypot64LoginConfig?

        public init(
            profile: Honeypot64Profile? = nil,
            services: [Honeypot64ServiceConfig]? = nil,
            scan: Bool? = nil,
            maxConnsPerIP: Int? = nil,
            maxConnsTotal: Int? = nil,
            retentionDays: Int? = nil,
            maxEvents: Int? = nil,
            notifyNew: Bool? = nil,
            report: Bool? = nil,
            noLocalBlock: Bool? = nil,
            country: String? = nil,
            log: Honeypot64LogConfig? = nil,
            certID: Int? = nil,
            certPorts: [Int]? = nil,
            login: Honeypot64LoginConfig? = nil
        ) {
            self.profile = profile
            self.services = services
            self.scan = scan
            self.maxConnsPerIP = maxConnsPerIP
            self.maxConnsTotal = maxConnsTotal
            self.retentionDays = retentionDays
            self.maxEvents = maxEvents
            self.notifyNew = notifyNew
            self.report = report
            self.noLocalBlock = noLocalBlock
            self.country = country
            self.log = log
            self.certID = certID
            self.certPorts = certPorts
            self.login = login
        }

        enum CodingKeys: String, CodingKey {
            case profile, services, scan
            case maxConnsPerIP = "max_conns_per_ip"
            case maxConnsTotal = "max_conns_total"
            case retentionDays = "retention_days"
            case maxEvents = "max_events"
            case notifyNew = "notify_new"
            case report
            case noLocalBlock = "no_local_block"
            case country, log
            case certID = "cert_id"
            case certPorts = "cert_ports"
            case login
        }
    }

    /// Monitoring of the node's own login (rule `node64/login@1`), inline in ``Honeypot64Config``.
    ///
    /// Missing = on, 5 failures in 10 minutes, with notification.
    public struct Honeypot64LoginConfig: Codable, Hashable, Sendable {
        /// Switch the monitoring off.
        public var off: Bool?
        /// Failed attempts per IP in the window (2-100, 0 = 5).
        public var threshold: Int?
        /// Window in minutes (1-1440, 0 = 10).
        public var windowMin: Int?
        /// No notification.
        public var noNotify: Bool?

        public init(off: Bool? = nil, threshold: Int? = nil, windowMin: Int? = nil, noNotify: Bool? = nil) {
            self.off = off
            self.threshold = threshold
            self.windowMin = windowMin
            self.noNotify = noNotify
        }

        enum CodingKeys: String, CodingKey {
            case off, threshold
            case windowMin = "window_min"
            case noNotify = "no_notify"
        }
    }

    /// Log sensor and syslog receiver. Schema `Honeypot64LogConfig`.
    public struct Honeypot64LogConfig: Codable, Hashable, Sendable {
        /// Log files to watch (at most 32).
        public var files: [Honeypot64LogFile]?
        /// Syslog port, 0 = off (UDP and TCP).
        public var syslogPort: Int?
        /// Allowed senders (IP/CIDR); empty = private networks and localhost (at most 64).
        public var syslogAllow: [String]?

        public init(files: [Honeypot64LogFile]? = nil, syslogPort: Int? = nil, syslogAllow: [String]? = nil) {
            self.files = files
            self.syslogPort = syslogPort
            self.syslogAllow = syslogAllow
        }

        enum CodingKeys: String, CodingKey {
            case files
            case syslogPort = "syslog_port"
            case syslogAllow = "syslog_allow"
        }
    }

    /// A log file to watch. Schema `Honeypot64LogFile`.
    public struct Honeypot64LogFile: Codable, Hashable, Sendable {
        /// Absolute path or glob under `/host/log`, `/var/log` or `/data/logs`.
        public var path: String
        /// Log format; empty/auto = automatic.
        public var format: Honeypot64LogFormat?

        public init(path: String, format: Honeypot64LogFormat? = nil) {
            self.path = path
            self.format = format
        }
    }

    /// A service of the custom selection. Schema `Honeypot64ServiceConfig`.
    public struct Honeypot64ServiceConfig: Codable, Hashable, Sendable {
        /// Service, e.g. `ssh`, `http`, `mysql` (full list: ``Honeypot64Catalog/services``).
        public var service: String
        /// Port (1-65535).
        public var port: Int
        /// Decoy page (only http/https); empty = selection per path.
        public var page: Honeypot64DecoyPage?

        public init(service: String, port: Int, page: Honeypot64DecoyPage? = nil) {
            self.service = service
            self.port = port
            self.page = page
        }
    }
}
