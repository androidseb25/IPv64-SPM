import Foundation

extension Node64 {
    /// Result of ``Node64/Proxy64/check()``.
    public struct Proxy64CheckResult: Codable, Hashable, Sendable {
        /// The check is running.
        public let checking: Bool?
    }

    /// What the proxy answers for unknown names.
    public struct Proxy64DefaultMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Answer with 404.
        public static let notFound: Self = "404"
        /// Close the connection.
        public static let close: Self = "close"
        /// Redirect to `defaultURL`.
        public static let redirect: Self = "redirect"
        /// Serve `defaultHTML`.
        public static let html: Self = "html"
    }

    /// Default page for unknown names (read and write).
    public struct Proxy64DefaultPage: Codable, Hashable, Sendable {
        /// What to answer for unknown names.
        public var mode: Proxy64DefaultMode?
        /// Address for mode `redirect`.
        public var url: String?
        /// Page for mode `html`, at most 64 KB.
        public var html: String?

        /// Creates an instance; pass only the fields you want to set.
        public init(mode: Proxy64DefaultMode? = nil, url: String? = nil, html: String? = nil) {
            self.mode = mode
            self.url = url
            self.html = html
        }

        enum CodingKeys: String, CodingKey {
            case mode = "default"
            case url = "default_url"
            case html = "default_html"
        }
    }

    /// An access log entry.
    public struct Proxy64LogEntry: Codable, Hashable, Sendable, Identifiable {
        /// ID of the log entry.
        public let id: Int?
        /// Time of the request.
        public let time: Date?
        /// `0` = connection dropped before the first request.
        public let hostID: Int?
        /// Client address.
        public let client: String?
        /// HTTP method.
        public let method: String?
        /// Host name of the request.
        public let host: String?
        /// Request path.
        public let path: String?
        /// HTTP status; `0` = connection dropped before the first request.
        public let status: Int?
        /// Number of bytes sent.
        public let bytes: Int?
        /// Duration in milliseconds.
        public let ms: Int?
        /// User agent of the client.
        public let userAgent: String?
        /// Why the request was rejected (`blocklist`, `ban`, `conns`, `conn_rate`, `max_conns`, `req_rate`, `target`, `exploit`, `acl`).
        public let reason: String?

        enum CodingKeys: String, CodingKey {
            case id, time
            case hostID = "host_id"
            case client, method, host, path, status, bytes, ms
            case userAgent = "user_agent"
            case reason
        }
    }

    /// Retention settings of the access log.
    public struct Proxy64Settings: Codable, Hashable, Sendable {
        /// Days to keep, 1-90.
        public var logDays: Int?
        /// Anonymize client addresses.
        public var anonymize: Bool?

        /// Creates an instance; pass only the fields you want to set.
        public init(logDays: Int? = nil, anonymize: Bool? = nil) {
            self.logDays = logDays
            self.anonymize = anonymize
        }

        enum CodingKeys: String, CodingKey {
            case logDays = "log_days"
            case anonymize
        }
    }

    /// Result of creating a health check for a host or stream target.
    public struct Proxy64HealthcheckResult: Codable, Hashable, Sendable {
        /// Token of the new health check.
        public let token: String?
    }
}
