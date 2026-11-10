import Foundation

extension Node64 {
    /// Sort field of ``Node64/DNS64/topList(kind:range:query:sort:direction:limit:offset:)``.
    public struct DNS64TopSort: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// By number of queries (default).
        public static let count: Self = "count"
        /// By name.
        public static let name: Self = "name"
        /// By number of blocked queries.
        public static let blocked: Self = "blocked"
    }

    /// Sort direction of a list.
    public struct DNS64SortDirection: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let ascending: Self = "asc"
        public static let descending: Self = "desc"
    }

    /// A page of the full top list, result of ``Node64/DNS64/topList(kind:range:query:sort:direction:limit:offset:)``.
    public struct DNS64TopPage: Codable, Hashable, Sendable {
        /// Entries of this page.
        public let items: [DNS64TopItem]?
        /// Number of all names in the time range (with the search applied).
        public let total: Int?
    }

    /// Result of adding several lists with `urls`. Schema inline in `POST /dns64/lists` and `POST /dns64/allowlists`.
    public struct DNS64ListsAddResult: Codable, Hashable, Sendable {
        /// URLs that were added.
        public let added: [String]?
        /// URLs that already existed.
        public let duplicates: [String]?
        /// URLs that were not valid.
        public let invalid: [String]?
    }

    /// An entry of the own deny list. Entry of ``Node64/DNS64/Denylist/list()``.
    public struct DNS64DenylistEntry: Codable, Hashable, Sendable, Identifiable {
        /// The blocked domain (applies to subdomains too).
        public let domain: String?
        /// When it was added.
        public let addedAt: Date?

        /// Identifier for `Identifiable` (the domain).
        public var id: String { domain ?? "" }
    }

    /// Result of ``Node64/DNS64/Denylist/add(_:)``.
    public struct DNS64DenylistAdded: Codable, Hashable, Sendable {
        /// The normalized domain.
        public let domain: String?
    }

    /// Result of ``Node64/DNS64/Denylist/replace(_:)``.
    public struct DNS64DenylistReplaceResult: Codable, Hashable, Sendable {
        /// Entries in the list now.
        public let total: Int?
        /// Entries added.
        public let added: Int?
        /// Entries removed.
        public let removed: Int?
        /// Duplicates in the input.
        public let duplicates: Int?
        /// Invalid lines (at most 20).
        public let invalid: [String]?
    }

    /// A service that can be blocked per click. Entry of ``DNS64Services/services``.
    public struct DNS64Service: Codable, Hashable, Sendable, Identifiable {
        /// Key to pass in `categories` of a group rule or schedule, e.g. `svc:tiktok`.
        public let key: String?
        /// Service ID.
        public let id: String
        /// Display name.
        public let name: String?
        /// Group of the service, e.g. `social`.
        public let group: String?
        /// Domains the service uses.
        public let domains: [String]?

        enum CodingKeys: String, CodingKey {
            case key, id, name, group, domains
        }

        /// Decodes a service; a missing `id` falls back to the part of `key` after `svc:`.
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            key = try c.decodeIfPresent(String.self, forKey: .key)
            name = try c.decodeIfPresent(String.self, forKey: .name)
            group = try c.decodeIfPresent(String.self, forKey: .group)
            domains = try c.decodeIfPresent([String].self, forKey: .domains)
            id = try c.decodeIfPresent(String.self, forKey: .id)
                ?? key.map { $0.hasPrefix("svc:") ? String($0.dropFirst(4)) : $0 } ?? ""
        }
    }

    /// Categories and services a group can block, result of ``Node64/DNS64/services()``.
    public struct DNS64Services: Codable, Hashable, Sendable {
        /// Category names.
        public let categories: [String]?
        /// Service groups, e.g. `ai`, `social`, `messenger`.
        public let groups: [String]?
        /// Services; block one with its `key` in `categories`.
        public let services: [DNS64Service]?
    }

    /// Why a Docker entry could not be applied.
    public struct DNS64DockerProblem: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// The container has no IP address.
        public static let noIP: Self = "no_ip"
        /// The IP address is invalid.
        public static let badIP: Self = "bad_ip"
        /// The name is invalid.
        public static let badName: Self = "bad_name"
        /// The name already has another entry.
        public static let taken: Self = "taken"
        /// Creating the entry failed.
        public static let failed: Self = "failed"
    }

    /// A container with a `node64.dns.name` label. Entry of ``DNS64Docker/containers``.
    public struct DNS64DockerContainer: Codable, Hashable, Sendable, Identifiable {
        /// Container name.
        public let container: String?
        /// Container state.
        public let state: String?
        /// DNS names of the container.
        public let names: [String]?
        /// Addresses the names point to.
        public let addrs: [String]?
        /// Why the entry was not applied, if it was not.
        public let problem: DNS64DockerProblem?
        /// Name the problem refers to.
        public let problemName: String?

        /// Identifier for `Identifiable` (the container name).
        public var id: String { container ?? "" }

        enum CodingKeys: String, CodingKey {
            case container, state, names, addrs, problem
            case problemName = "problem_name"
        }
    }

    /// Sync state of the Docker labels, result of ``Node64/DNS64/docker()``.
    public struct DNS64Docker: Codable, Hashable, Sendable {
        /// Whether the integration is on (`docker` in the settings).
        public let enabled: Bool?
        /// Whether the Docker API is reachable.
        public let connected: Bool?
        /// Docker API, e.g. `unix:///var/run/docker.sock`.
        public let host: String?
        /// Last error message.
        public let error: String?
        /// Time of the last sync.
        public let synced: Date?
        /// Containers with their entries.
        public let containers: [DNS64DockerContainer]?
    }

    /// Key for dynamic updates (TSIG) of a zone. **Contains secret key material.**
    ///
    /// Result of ``Node64/DNS64/Zones/tsig(_:)`` and ``Node64/DNS64/Zones/regenerateTSIG(_:)``.
    public struct DNS64ZoneTSIG: Codable, Hashable, Sendable {
        /// Name of the zone.
        public let zone: String?
        /// Whether dynamic updates are on.
        public let dynamic: Bool?
        /// Algorithm, e.g. `hmac-sha256`.
        public let algorithm: String?
        /// Key name.
        public let tsigName: String?
        /// Key (Base64). Secret: shown only by these endpoints, never in lists, exports or the cluster. Do not log it.
        public let tsigSecret: String?

        enum CodingKeys: String, CodingKey {
            case zone, dynamic, algorithm
            case tsigName = "tsig_name"
            case tsigSecret = "tsig_secret"
        }
    }
}
