import Foundation

/// A state-change event of a check.
public struct HC2Event: Codable, Hashable, Sendable, Identifiable {
    /// Event number (cursor for `before`/`after`).
    public let id: Int
    /// Event identifier.
    public let eventID: String?
    /// Token of the check.
    public let token: String?
    /// Source; empty means the overall state.
    public let source: String?
    /// Human-readable name of the source.
    public let sourceLabel: String?
    /// Kind of event.
    public let kind: HC2EventKind?
    /// Time of the event.
    public let time: Date?
    /// Previous state.
    public let fromState: String?
    /// New state.
    public let toState: String?
    /// Reason.
    public let reason: String?
    /// Message.
    public let message: String?
    /// Duration of the previous state in seconds.
    public let durationSeconds: Int?
    /// Number of flaps.
    public let flaps: Int?
    /// Without alarm.
    public let silent: Bool?
    /// Related incident.
    public let incidentID: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case token, source
        case sourceLabel = "source_label"
        case kind, time
        case fromState = "from_state"
        case toState = "to_state"
        case reason, message
        case durationSeconds = "duration_seconds"
        case flaps, silent
        case incidentID = "incident_id"
    }
}

/// Pagination metadata of cursor-paginated healthchecks 2.0 lists.
///
/// Pass ``nextBefore`` as `before` to fetch older entries, or ``nextAfter`` as `after` to fetch newer ones.
public struct HC2PageMeta: Codable, Hashable, Sendable {
    /// Page size used.
    public let limit: Int?
    /// More entries are available.
    public let hasMore: Bool?
    /// Cursor for the next older page.
    public let nextBefore: Int?
    /// Cursor for the next newer page.
    public let nextAfter: Int?

    enum CodingKeys: String, CodingKey {
        case limit
        case hasMore = "has_more"
        case nextBefore = "next_before"
        case nextAfter = "next_after"
    }
}
