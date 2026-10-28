import Foundation

extension Node64 {
    /// Statistics of a period. Schema `Honeypot64Stats`.
    public struct Honeypot64Stats: Codable, Hashable, Sendable {
        /// Start of the period.
        public let since: Date?
        /// Events.
        public let events: Int?
        /// Distinct source IPs.
        public let sources: Int?
        /// Login attempts.
        public let logins: Int?
        /// Events per service.
        public let byService: [Honeypot64Count]?
        /// Events per port.
        public let byPort: [Honeypot64Count]?
        /// Events per kind.
        public let byKind: [Honeypot64Count]?
        /// Top source IPs.
        public let topSources: [Honeypot64Count]?
        /// Top user names.
        public let topUsers: [Honeypot64Count]?
        /// Top passwords.
        public let topPasswords: [Honeypot64Count]?
        /// Top credentials, key = `user:password`.
        public let topCredentials: [Honeypot64Count]?
        /// Top paths.
        public let topPaths: [Honeypot64Count]?
        /// Top user agents.
        public let topUserAgents: [Honeypot64Count]?
        /// Top client fingerprints, key = `ja4:…` or `hassh:…`.
        public let topFingerprints: [Honeypot64Count]?
        /// Course over time (per hour up to 48 hours, otherwise per day).
        public let timeline: [Honeypot64TimelinePoint]?
        /// Events per sensor (honeypot, log, syslog).
        public let bySource: [Honeypot64Count]?
        /// Origin countries by count (at most 250).
        public let byCountry: [Honeypot64CountryCount]?
        /// Events without a country.
        public let countryUnknown: Int?
        /// Decoys and detected devices, key = `page:…` or `device:…`.
        public let byDecoy: [Honeypot64Count]?

        enum CodingKeys: String, CodingKey {
            case since, events, sources, logins
            case byService = "by_service"
            case byPort = "by_port"
            case byKind = "by_kind"
            case topSources = "top_sources"
            case topUsers = "top_users"
            case topPasswords = "top_passwords"
            case topCredentials = "top_credentials"
            case topPaths = "top_paths"
            case topUserAgents = "top_user_agents"
            case topFingerprints = "top_fingerprints"
            case timeline
            case bySource = "by_source"
            case byCountry = "by_country"
            case countryUnknown = "country_unknown"
            case byDecoy = "by_decoy"
        }
    }

    /// Point of the timeline inline in ``Honeypot64Stats``.
    public struct Honeypot64TimelinePoint: Codable, Hashable, Sendable {
        /// Start of the bucket.
        public let time: Date?
        /// Events in the bucket.
        public let events: Int?
    }

    /// A ranking entry. Schema `Honeypot64Count`.
    public struct Honeypot64Count: Codable, Hashable, Sendable, Identifiable {
        /// Key (service, port, IP, …).
        public let key: String?
        /// Count.
        public let count: Int?
        /// Last occurrence.
        public let last: Date?
        /// Only for top sources: country of the source IP (ISO 3166 alpha-2).
        public let country: String?

        public var id: String { key ?? "" }
    }

    /// Events per country. Schema `Honeypot64CountryCount`.
    public struct Honeypot64CountryCount: Codable, Hashable, Sendable, Identifiable {
        /// Country (ISO 3166 alpha-2, upper case).
        public let key: String?
        /// Events.
        public let count: Int?
        /// Distinct source IPs.
        public let sources: Int?
        /// Last occurrence.
        public let last: Date?

        public var id: String { key ?? "" }
    }

    /// One recorded event. Schema `Honeypot64Event`.
    public struct Honeypot64Event: Codable, Hashable, Sendable {
        /// Time.
        public let time: Date?
        /// Service.
        public let service: String?
        /// Port.
        public let port: Int?
        /// Kind, e.g. `ssh:bruteforce`, `http:exploit:sqli`, `generic:probe`.
        public let kind: String?
        /// Source IP.
        public let src: String?
        /// Source port.
        public let srcPort: Int?
        /// Country of the source IP (ISO 3166 alpha-2).
        public let country: String?
        /// User name tried (plain text).
        public let username: String?
        /// Password tried (plain text).
        public let password: String?
        /// HTTP method.
        public let method: String?
        /// Path.
        public let path: String?
        /// Host.
        public let host: String?
        /// User agent.
        public let userAgent: String?
        /// Client.
        public let client: String?
        /// Decoy page.
        public let page: String?
        /// Detail.
        public let detail: String?
        /// Payload as hex.
        public let payloadHex: String?
        /// Payload as escaped ASCII text.
        public let payloadText: String?
        /// Sensor.
        public let source: Honeypot64Source?
        /// Rule (log/syslog), e.g. `sshd/bruteforce@1`.
        public let rule: String?
        /// Client fingerprint, `ja4:…` or `hassh:…`.
        public let fingerprint: String?
        /// Requested name (SNI or host).
        public let sni: String?

        enum CodingKeys: String, CodingKey {
            case time, service, port, kind, src
            case srcPort = "src_port"
            case country, username, password, method, path, host
            case userAgent = "user_agent"
            case client, page, detail
            case payloadHex = "payload_hex"
            case payloadText = "payload_text"
            case source, rule, fingerprint, sni
        }
    }

    /// Service catalog. Schema `Honeypot64Catalog`.
    public struct Honeypot64Catalog: Codable, Hashable, Sendable {
        /// Saved profile (`custom` = own selection).
        public let profile: String?
        /// Whether the sensor runs.
        public let running: Bool?
        /// Catalog entries.
        public let entries: [Honeypot64CatalogItem]?
        /// Selected services outside the catalog.
        public let extra: [Honeypot64CatalogItem]?
        /// Names of all services.
        public let services: [String]?
        /// Decoy pages.
        public let pages: [String]?
        /// Groups.
        public let groups: [String]?
        /// Profiles as templates.
        public let presets: [String: [Honeypot64ServiceConfig]]?
    }

    /// Catalog entry. Schema `Honeypot64CatalogItem`.
    public struct Honeypot64CatalogItem: Codable, Hashable, Sendable {
        /// Service.
        public let service: String?
        /// Configured or default port.
        public let port: Int?
        /// Default port of the catalog; missing for own entries.
        public let defaultPort: Int?
        /// Decoy (http/https only).
        public let page: String?
        /// Protocol.
        public let proto: Honeypot64Protocol?
        /// Group.
        public let group: Honeypot64CatalogGroup?
        /// Description.
        public let description: String?
        /// Profiles that contain exactly this entry.
        public let profiles: [String]?
        /// In the saved selection.
        public let on: Bool?
        /// Port state.
        public let state: Honeypot64PortState?
        /// Other part holding the port (used/reserved).
        public let owner: String?
        /// Purpose of the port there.
        public let purpose: String?
        /// Error text.
        public let error: String?
        /// Connections.
        public let conns: Int?

        enum CodingKeys: String, CodingKey {
            case service, port
            case defaultPort = "default_port"
            case page, proto, group, description, profiles, on, state, owner, purpose, error, conns
        }
    }

    /// Result of ``Node64/Honeypot/clearEvents()``.
    public struct Honeypot64DeleteResult: Codable, Hashable, Sendable {
        /// Number of deleted events.
        public let deleted: Int?
    }

    /// Live map data. Result of ``Node64/Honeypot/live(minutes:)``.
    public struct Honeypot64Live: Codable, Hashable, Sendable {
        /// Period in minutes.
        public let minutes: Int?
        /// Server time in Unix milliseconds.
        public let now: Int?
        /// Target of the arcs (country of the node's public IPv4).
        public let target: Honeypot64LiveTarget?
        /// Events with a known origin country (newest first, at most 500).
        public let events: [Honeypot64LiveEvent]?
    }

    /// Target of the arcs on the live map.
    public struct Honeypot64LiveTarget: Codable, Hashable, Sendable {
        /// Country code.
        public let cc: String?
        /// Flag emoji.
        public let flag: String?
        /// Country name.
        public let name: String?
        /// X on the country map (viewBox 0 0 1000 436).
        public let x: Double?
        /// Y on the country map.
        public let y: Double?
        /// Location known.
        public let known: Bool?
        /// `true` = configured location, otherwise from the public IPv4.
        public let manual: Bool?
    }

    /// Event on the live map.
    public struct Honeypot64LiveEvent: Codable, Hashable, Sendable {
        /// Time in Unix milliseconds.
        public let t: Int?
        /// Country code.
        public let cc: String?
        /// Flag emoji.
        public let flag: String?
        /// Country name.
        public let name: String?
        /// X on the country map.
        public let x: Double?
        /// Y on the country map.
        public let y: Double?
        /// Source IP.
        public let ip: String?
        /// Kind.
        public let kind: String?
        /// Group.
        public let group: Honeypot64EventGroup?
        /// Service.
        public let service: String?
        /// Port.
        public let port: Int?
        /// Sensor.
        public let source: String?
    }
}
