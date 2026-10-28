import Foundation

/// A maintenance window.
public struct HC2Maintenance: Codable, Hashable, Sendable, Identifiable {
    /// Maintenance window ID.
    public let id: Int
    /// Name.
    public let name: String?
    /// Start.
    public let startAt: Date?
    /// End.
    public let endAt: Date?
    /// Repetition.
    public let `repeat`: HC2MaintenanceRepeat?
    /// Repeat until.
    public let repeatUntil: Date?
    /// Check tokens; empty means all checks.
    public let tokens: [String]?
    /// Active.
    public let active: Bool?
    /// Node ID.
    public let nodeID: String?
    /// Revision.
    public let revision: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case startAt = "start_at"
        case endAt = "end_at"
        case `repeat`
        case repeatUntil = "repeat_until"
        case tokens, active
        case nodeID = "node_id"
        case revision
    }
}

/// Request body for creating or updating a maintenance window.
public struct HC2MaintenanceInput: Encodable, Hashable, Sendable {
    /// Name.
    public var name: String
    /// Start.
    public var startAt: Date?
    /// End.
    public var endAt: Date?
    /// Repetition.
    public var `repeat`: HC2MaintenanceRepeat?
    /// Repeat until.
    public var repeatUntil: Date?
    /// Check tokens; empty means all checks.
    public var tokens: [String]?
    /// Active.
    public var active: Bool?

    /// Creates a maintenance body. The API requires `startAt` and `endAt` when creating.
    public init(
        name: String,
        startAt: Date? = nil,
        endAt: Date? = nil,
        repeat: HC2MaintenanceRepeat? = nil,
        repeatUntil: Date? = nil,
        tokens: [String]? = nil,
        active: Bool? = nil
    ) {
        self.name = name
        self.startAt = startAt
        self.endAt = endAt
        self.repeat = `repeat`
        self.repeatUntil = repeatUntil
        self.tokens = tokens
        self.active = active
    }

    enum CodingKeys: String, CodingKey {
        case name
        case startAt = "start_at"
        case endAt = "end_at"
        case `repeat`
        case repeatUntil = "repeat_until"
        case tokens, active
    }
}
