import Foundation

/// An incident (period of failure) of a check.
public struct HC2Incident: Codable, Hashable, Sendable, Identifiable {
    /// Incident number.
    public let id: Int
    /// Token of the check.
    public let token: String?
    /// Name of the check.
    public let name: String?
    /// `open` or `closed`.
    public let status: HC2IncidentStatus?
    /// Start of the incident.
    public let startedAt: Date?
    /// End of the incident.
    public let endedAt: Date?
    /// Duration in seconds.
    public let durationSeconds: Int?
    /// Reason.
    public let reason: String?
    /// Message.
    public let message: String?
    /// Affected measuring points.
    public let sources: [String]?

    enum CodingKeys: String, CodingKey {
        case id, token, name, status
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case reason, message, sources
    }
}
