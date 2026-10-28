import Foundation

extension Node64 {
    /// Device group with members, filter rules, schedules and its current state. Schema `DNS64Group`.
    public struct DNS64Group: Codable, Hashable, Sendable, Identifiable {
        /// ID of the group.
        public let id: Int
        /// Name of the group.
        public let name: String?
        /// Position in the order of precedence (groups are evaluated in this order).
        public let position: Int?
        /// Devices and networks assigned to the group.
        public let members: [DNS64GroupMember]?
        /// Whether the global or custom block lists apply.
        public let listsMode: DNS64GroupListsMode?
        /// Block list URLs when ``listsMode`` is `custom`.
        public let lists: [String]?
        /// Blocked categories.
        public let categories: [DNS64GroupCategory]?
        /// Allow and block entries of the group (including subdomains).
        public let domains: [DNS64GroupDomain]?
        /// Whether safe search is enforced.
        public let safesearch: Bool?
        /// YouTube restriction mode.
        public let youtube: DNS64GroupYouTubeMode?
        /// Whether the group bypasses the filters.
        public let bypass: Bool?
        /// Active instant button (hold) mode.
        public let hold: DNS64GroupHoldMode?
        /// RFC 3339 end of the hold; empty means until released.
        public let holdUntil: String?
        /// Schedules of the group.
        public let schedules: [DNS64Schedule]?
        /// Current state of the group (only returned by `GET`).
        public let state: DNS64GroupState?
        /// Cluster-wide identifier (identical on all nodes, read-only).
        public let uid: String?

        enum CodingKeys: String, CodingKey {
            case id, name, position, members
            case listsMode = "lists_mode"
            case lists, categories, domains, safesearch, youtube, bypass, hold
            case holdUntil = "hold_until"
            case schedules, state, uid
        }
    }

    /// Current state of a group (inline object of `DNS64Group.state`).
    public struct DNS64GroupState: Codable, Hashable, Sendable {
        /// The internet is currently off for the group.
        public let internetOff: Bool?
        /// Schedules and categories are currently suspended.
        public let free: Bool?
        /// The state was caused by the instant button.
        public let byButton: Bool?
        /// The state lasts until it is released manually.
        public let untilReleased: Bool?
        /// End of the current state.
        public let until: Date?
        /// Label of the schedule that caused the state.
        public let schedule: String?

        enum CodingKeys: String, CodingKey {
            case internetOff = "internet_off"
            case free
            case byButton = "by_button"
            case untilReleased = "until_released"
            case until, schedule
        }
    }

    /// Device or network assigned to a group. Schema `DNS64GroupMember`.
    public struct DNS64GroupMember: Codable, Hashable, Sendable, Identifiable {
        /// ID of the membership.
        public let id: Int?
        /// ID of the group.
        public let groupID: Int?
        /// Kind of the value.
        public let kind: DNS64GroupMemberKind
        /// MAC address, IP address or network (CIDR).
        public let value: String
        /// Optional label (used for device names in zones).
        public let label: String?

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case kind, value, label
        }
    }

    /// Allow or block entry of a group (applies to subdomains too). Schema `DNS64GroupDomain`.
    public struct DNS64GroupDomain: Codable, Hashable, Sendable, Identifiable {
        /// ID of the entry.
        public let id: Int?
        /// ID of the group.
        public let groupID: Int?
        /// Domain, e.g. `tiktok.com`.
        public let domain: String
        /// Allow or block.
        public let action: DNS64GroupDomainAction

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case domain, action
        }
    }

    /// Time schedule of a group. Schema `DNS64Schedule`.
    public struct DNS64Schedule: Codable, Hashable, Sendable, Identifiable {
        /// ID of the schedule.
        public let id: Int?
        /// ID of the group.
        public let groupID: Int?
        /// Label.
        public let label: String?
        /// Weekdays, 1 = Monday ... 7 = Sunday.
        public let days: [Int]
        /// Start time, e.g. `21:00`.
        public let start: String
        /// End time, e.g. `07:00`.
        public let end: String
        /// What the schedule does.
        public let action: DNS64ScheduleAction
        /// Categories blocked when ``action`` is `cats`.
        public let categories: [DNS64GroupCategory]?
        /// Whether the schedule is active.
        public let enabled: Bool?

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case label, days, start, end, action, categories, enabled
        }
    }

    /// Writable fields of a schedule for ``Node64/DNS64/Groups/Schedules/create(group:_:)``.
    public struct DNS64ScheduleInput: Encodable, Hashable, Sendable {
        /// Weekdays, 1 = Monday ... 7 = Sunday.
        public var days: [Int]
        /// Start time, e.g. `21:00`.
        public var start: String
        /// End time, e.g. `07:00`.
        public var end: String
        /// What the schedule does.
        public var action: DNS64ScheduleAction
        /// Label.
        public var label: String?
        /// Categories blocked when `action` is `cats`.
        public var categories: [DNS64GroupCategory]?
        /// Whether the schedule is active.
        public var enabled: Bool?

        /// Creates a schedule input; optional fields left `nil` are not sent.
        public init(
            days: [Int], start: String, end: String, action: DNS64ScheduleAction,
            label: String? = nil, categories: [DNS64GroupCategory]? = nil, enabled: Bool? = nil
        ) {
            self.days = days
            self.start = start
            self.end = end
            self.action = action
            self.label = label
            self.categories = categories
            self.enabled = enabled
        }
    }

    /// Whether a group uses the global or its own block lists.
    public struct DNS64GroupListsMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        /// Global block lists.
        public static let global: Self = "global"
        /// Custom block lists of the group.
        public static let custom: Self = "custom"
    }

    /// Content category a group can block.
    public struct DNS64GroupCategory: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let social: Self = "social"
        public static let games: Self = "games"
        public static let streaming: Self = "streaming"
        public static let gambling: Self = "gambling"
        public static let adult: Self = "adult"
    }

    /// YouTube restriction mode of a group.
    public struct DNS64GroupYouTubeMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let strict: Self = "strict"
        public static let moderate: Self = "moderate"
        public static let off: Self = "off"
    }

    /// Instant button mode of a group.
    public struct DNS64GroupHoldMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        /// Internet off.
        public static let block: Self = "block"
        /// Schedules and categories suspended.
        public static let free: Self = "free"
        /// No hold (releases an active one).
        public static let none: Self = ""
    }

    /// Kind of a group member value.
    public struct DNS64GroupMemberKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let mac: Self = "mac"
        public static let ip: Self = "ip"
        public static let net: Self = "net"
    }

    /// Action of a group domain entry.
    public struct DNS64GroupDomainAction: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let allow: Self = "allow"
        public static let block: Self = "block"
    }

    /// Action of a schedule.
    public struct DNS64ScheduleAction: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        /// Internet off.
        public static let off: Self = "off"
        /// Block the schedule's categories.
        public static let cats: Self = "cats"
    }
}
