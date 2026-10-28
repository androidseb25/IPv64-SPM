import Foundation

/// An event of a healthcheck (status change, ping or check result).
public struct HealthcheckEvent: Codable, Hashable, Sendable, Identifiable {
    /// Event ID, also used as pagination cursor.
    public let id: Int
    /// Time of the event.
    public let time: Date?
    /// Status.
    public let status: HealthcheckStatus?
    /// Message, e.g. `Healthcheck is UP`.
    public let message: String?
    /// Response time in milliseconds.
    public let latencyMs: Double?
    /// Additional data of the ping.
    public let payload: JSONValue?

    enum CodingKeys: String, CodingKey {
        case id, time, status, message
        case latencyMs = "latency_ms"
        case payload
    }
}

/// Pagination metadata of ``IPv64/Healthchecks/events(_:limit:before:after:since:)``.
public struct HealthcheckEventsMeta: Codable, Hashable, Sendable {
    /// Limit used for the request.
    public let limit: Int?
    /// More events are available.
    public let hasMore: Bool?
    /// Cursor for the next page when `after` was not used.
    public let nextBefore: Int?
    /// Cursor for the next page when `after` was used.
    public let nextAfter: Int?

    enum CodingKeys: String, CodingKey {
        case limit
        case hasMore = "has_more"
        case nextBefore = "next_before"
        case nextAfter = "next_after"
    }
}
