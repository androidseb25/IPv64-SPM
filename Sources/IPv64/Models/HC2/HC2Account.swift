import Foundation

/// Healthchecks 2.0 account: plan, limits and locations.
public struct HC2Account: Codable, Hashable, Sendable {
    /// Plan name.
    public let plan: String?
    /// Online measuring points in use and their limit.
    public let onlineMeasuringPoints: Usage?
    /// Daily quota: online measurements per location plus pushes to the online address (day in Europe/Berlin). When reached, online checks pause until midnight.
    public let checksPerDay: Usage?
    /// Locations per check.
    public let locationsPerCheck: Int?
    /// SMS per day.
    public let smsPerDay: Int?
    /// Available locations.
    public let locations: [Location]?
    /// Node counts.
    public let nodes: Nodes?
    /// Number of checks.
    public let checks: Int?

    /// Usage against a limit.
    public struct Usage: Codable, Hashable, Sendable {
        /// Used.
        public let used: Int?
        /// Limit; `nil` means unlimited.
        public let limit: Int?
    }

    /// A measuring location.
    public struct Location: Codable, Hashable, Sendable {
        /// Code, e.g. `nbg`.
        public let code: String?
        /// Name.
        public let name: String?
    }

    /// Node counts.
    public struct Nodes: Codable, Hashable, Sendable {
        /// Total number of nodes.
        public let total: Int?
        /// Number of online nodes.
        public let online: Int?
    }

    enum CodingKeys: String, CodingKey {
        case plan
        case onlineMeasuringPoints = "online_measuring_points"
        case checksPerDay = "checks_per_day"
        case locationsPerCheck = "locations_per_check"
        case smsPerDay = "sms_per_day"
        case locations, nodes, checks
    }
}
