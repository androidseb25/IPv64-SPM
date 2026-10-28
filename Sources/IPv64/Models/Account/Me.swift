import Foundation

/// Account, plan, usage and the credentials used for the request.
public struct Me: Codable, Hashable, Sendable, Identifiable {
    /// Account ID.
    public let id: Int
    /// Email address.
    public let email: String?
    /// Username.
    public let username: String?
    /// Registration time.
    public let registeredAt: Date?
    /// Last login on the website.
    public let lastLoginAt: Date?
    /// Current plan.
    public let plan: Plan?
    /// Usage and limits.
    public let usage: Usage?
    /// Number of days logs are kept.
    public let logRetentionDays: Int?
    /// Credentials used for this request.
    public let auth: Auth?

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case registeredAt = "registered_at"
        case lastLoginAt = "last_login_at"
        case plan, usage
        case logRetentionDays = "log_retention_days"
        case auth
    }

    /// The plan of the account.
    public struct Plan: Codable, Hashable, Sendable {
        /// Plan ID.
        public let id: Int?
        /// Plan name, e.g. `VIP`.
        public let name: String?
        /// End of the term; `nil` for the free plan.
        public let validUntil: Date?

        enum CodingKeys: String, CodingKey {
            case id, name
            case validUntil = "valid_until"
        }
    }

    /// Consumption against a limit.
    public struct Quota: Codable, Hashable, Sendable {
        /// Amount used.
        public let used: Double?
        /// Limit of the plan; `nil` means unlimited.
        public let limit: Int?
    }

    /// Cloud router traffic consumption.
    public struct TrafficQuota: Codable, Hashable, Sendable {
        /// Amount used in GB.
        public let used: Double?
        /// Limit in GB.
        public let limit: Int?
        /// The traffic limit has been reached.
        public let limited: Bool?
    }

    /// Usage and limits of the plan.
    public struct Usage: Codable, Hashable, Sendable {
        /// DynDNS domains.
        public let dyndnsDomains: Quota?
        /// Own domains.
        public let ownDomains: Quota?
        /// DynDNS updates of the last 24 hours.
        public let dyndnsUpdates24h: Quota?
        /// Healthchecks.
        public let healthchecks: Quota?
        /// Healthcheck pings of the last 24 hours.
        public let healthcheckPings24h: Quota?
        /// SMS of the last 24 hours.
        public let sms24h: Quota?
        /// DNS failover policies.
        public let failoverPolicies: Quota?
        /// DNS failover monitors.
        public let failoverMonitors: Quota?
        /// DNS failover rules.
        public let failoverRules: Quota?
        /// CDN domains.
        public let cdnDomains: Quota?
        /// CDN traffic of the current month in GB.
        public let cdnTrafficGB: Quota?
        /// Cloud router traffic in GB.
        public let vpnTrafficGB: TrafficQuota?
        /// DNS64 clients.
        public let dns64Clients: Quota?

        enum CodingKeys: String, CodingKey {
            case dyndnsDomains = "dyndns_domains"
            case ownDomains = "own_domains"
            case dyndnsUpdates24h = "dyndns_updates_24h"
            case healthchecks
            case healthcheckPings24h = "healthcheck_pings_24h"
            case sms24h = "sms_24h"
            case failoverPolicies = "failover_policies"
            case failoverMonitors = "failover_monitors"
            case failoverRules = "failover_rules"
            case cdnDomains = "cdn_domains"
            case cdnTrafficGB = "cdn_traffic_gb"
            case vpnTrafficGB = "vpn_traffic_gb"
            case dns64Clients = "dns64_clients"
        }
    }

    /// The credentials used for the request.
    public struct Auth: Codable, Hashable, Sendable {
        /// Kind of key.
        public let type: Kind?
        /// ID of the API key.
        public let keyID: Int?
        /// Name of the API key.
        public let keyName: String?
        /// With `X-IPv64-Act-As`: the account being acted for.
        public let actingFor: Int?
        /// With `X-IPv64-Act-As`: your own account.
        public let actingBy: Int?

        enum CodingKeys: String, CodingKey {
            case type
            case keyID = "key_id"
            case keyName = "key_name"
            case actingFor = "acting_for"
            case actingBy = "acting_by"
        }

        /// Kind of credential.
        public struct Kind: IPv64OpenEnum {
            public let rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }

            /// A regular API key.
            public static let apiKey: Self = "api_key"
            /// An account key.
            public static let accountKey: Self = "account_key"
        }
    }
}
