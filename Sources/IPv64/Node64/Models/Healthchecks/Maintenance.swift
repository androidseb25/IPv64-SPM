import Foundation

extension Node64 {
    /// A maintenance window. Schema `Maintenance`.
    public struct Maintenance: Codable, Hashable, Sendable, Identifiable {
        /// Window ID.
        public let id: Int
        /// Name.
        public let name: String?
        /// Start.
        public let startAt: String?
        /// End.
        public let endAt: String?
        /// Repetition.
        public let `repeat`: MaintenanceRepeat?
        /// End of the repetition.
        public let repeatUntil: String?
        /// Affected check tokens; empty means all.
        public let tokens: [String]?
        /// The window is enabled.
        public let active: Bool?
        /// Creation time.
        public let createdAt: Date?
        /// ID at ipv64 (read-only).
        public let remoteID: Int?
        /// Revision counter (read-only).
        public let revision: Int?

        enum CodingKeys: String, CodingKey {
            case id, name
            case startAt = "start_at"
            case endAt = "end_at"
            case `repeat`
            case repeatUntil = "repeat_until"
            case tokens, active
            case createdAt = "created_at"
            case remoteID = "remote_id"
            case revision
        }
    }

    /// Body to create or replace a maintenance window. Schema `MaintenanceInput`.
    ///
    /// An update replaces the whole window, so `nil` optional fields reset to their defaults.
    public struct MaintenanceInput: Encodable, Hashable, Sendable {
        /// Name.
        public var name: String
        /// Start.
        public var startAt: Date
        /// End; after `startAt`, at most 30 days later.
        public var endAt: Date
        /// Repetition.
        public var `repeat`: MaintenanceRepeat?
        /// End of the repetition.
        public var repeatUntil: Date?
        /// Affected check tokens; empty means all.
        public var tokens: [String]?
        /// Enabled (server default `true`).
        public var active: Bool?

        public init(
            name: String,
            startAt: Date,
            endAt: Date,
            repeat: MaintenanceRepeat? = nil,
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
}
