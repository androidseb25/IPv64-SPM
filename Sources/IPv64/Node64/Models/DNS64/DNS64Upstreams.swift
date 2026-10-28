import Foundation

extension Node64 {
    /// Status of a blocklist. Schema `DNS64ListStatus`.
    public struct DNS64ListStatus: Codable, Hashable, Sendable, Identifiable {
        /// Display name.
        public let name: String?
        /// Download URL.
        public let url: String?
        /// Number of rules loaded from the list.
        public let rules: Int?
        /// Last successful update.
        public let updatedAt: Date?
        /// Last error message, if any.
        public let error: String?
        /// Consecutive failures.
        public let failures: Int?

        /// Identifier for `Identifiable` (URL, else name).
        public var id: String { url ?? name ?? "" }
    }

    /// An upstream server with statistics. Schema `DNS64UpstreamStats`.
    public struct DNS64UpstreamStats: Codable, Hashable, Sendable, Identifiable {
        /// Display name.
        public let name: String?
        /// Server URL.
        public let url: String?
        /// Transport: `doh`, `dot` or `doq`.
        public let proto: DNS64Protocol?
        /// Bootstrap IP addresses.
        public let ips: [String]?
        /// Number of requests sent.
        public let requests: Int?
        /// Number of times it answered first.
        public let wins: Int?
        /// Number of errors.
        public let errors: Int?
        /// Average response time in milliseconds.
        public let avgMs: Double?
        /// Whether the server is currently healthy.
        public let healthy: Bool?
        /// Last error message.
        public let lastError: String?
        /// Time of the last error.
        public let lastErrorAt: Date?
        /// `fastest` mode: currently among the servers asked first.
        public let active: Bool?

        /// Identifier for `Identifiable` (URL, else name).
        public var id: String { url ?? name ?? "" }
    }

    /// Upstream servers and the router for local names, result of ``Node64/DNS64/Upstreams/list()``.
    public struct DNS64Upstreams: Codable, Hashable, Sendable {
        /// Mode: `fastest`, `parallel` or `ordered`.
        public let mode: DNS64UpstreamMode?
        /// Servers with statistics.
        public let servers: [DNS64UpstreamStats]?
        /// DNS server for local names.
        public let localDNS: String?
        /// Where `localDNS` comes from: `config` or `auto`.
        public let localSource: String?
        /// Number of servers.
        public let count: Int?
    }

    /// Cache counters since start. Schema `DNS64Cache`.
    public struct DNS64Cache: Codable, Hashable, Sendable {
        /// Current number of entries.
        public let entries: Int?
        /// Maximum number of entries.
        public let max: Int?
        /// Entries past their TTL.
        public let staleEntries: Int?
        /// Cache hits.
        public let hits: Int?
        /// Cache misses.
        public let misses: Int?
        /// Answers served from stale entries.
        public let staleServed: Int?
        /// Entries refreshed in the background.
        public let refreshed: Int?
        /// Failed background refreshes.
        public let refreshFailures: Int?
    }

    /// Result of ``Node64/DNS64/Cache/flush()``.
    public struct DNS64CacheFlushResult: Codable, Hashable, Sendable {
        /// Number of entries removed.
        public let flushed: Int?
    }

    /// An allowed domain, entry of ``Node64/DNS64/Allowlist/list()``.
    public struct DNS64AllowlistEntry: Codable, Hashable, Sendable, Identifiable {
        /// The domain (applies to subdomains too).
        public let domain: String?
        /// When it was added.
        public let addedAt: Date?

        /// Identifier for `Identifiable` (the domain).
        public var id: String { domain ?? "" }
    }

    /// Result of ``Node64/DNS64/Allowlist/add(_:)``.
    public struct DNS64AllowlistAdded: Codable, Hashable, Sendable {
        /// The normalized domain.
        public let domain: String?
    }

    /// Result of ``Node64/DNS64/Allowlist/importDomains(_:)``.
    public struct DNS64AllowlistImportResult: Codable, Hashable, Sendable {
        /// Domains added.
        public let imported: Int?
        /// Entries that were not valid domains.
        public let invalid: Int?
    }
}
