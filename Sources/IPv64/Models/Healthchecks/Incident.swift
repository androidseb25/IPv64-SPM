import Foundation

/// An incident of a healthcheck.
public struct Incident: Codable, Hashable, Sendable, Identifiable {
    /// Incident ID.
    public let id: Int
    /// Status.
    public let status: IncidentStatus?
    /// Start.
    public let createdAt: Date?
    /// End.
    public let closedAt: Date?
    /// Events belonging to the incident.
    public let events: [Event]?

    /// An event within an incident.
    public struct Event: Codable, Hashable, Sendable {
        /// Time of the event.
        public let time: Date?
        /// Kind, e.g. `down`.
        public let kind: String?
        /// Message, e.g. `Healthcheck is DOWN`.
        public let message: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, status
        case createdAt = "created_at"
        case closedAt = "closed_at"
        case events
    }
}
