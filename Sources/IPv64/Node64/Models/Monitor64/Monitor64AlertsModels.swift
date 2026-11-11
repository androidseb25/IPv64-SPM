import Foundation

// MARK: - Open enums

extension Node64 {
    /// State of a Monitor64 problem.
    public struct Monitor64ProblemRowState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `ok`
        public static let ok: Monitor64ProblemRowState = "ok"
        /// `warn`
        public static let warn: Monitor64ProblemRowState = "warn"
        /// `crit`
        public static let crit: Monitor64ProblemRowState = "crit"
        /// `unknown`
        public static let unknown: Monitor64ProblemRowState = "unknown"
        /// `unreachable`
        public static let unreachable: Monitor64ProblemRowState = "unreachable"
    }

    /// How a Monitor64 problem was closed.
    public struct Monitor64ProblemRowHow: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `auto`: the state recovered.
        public static let auto: Monitor64ProblemRowHow = "auto"
        /// `maint`: closed by a maintenance window.
        public static let maint: Monitor64ProblemRowHow = "maint"
        /// `user`: marked as resolved by a person.
        public static let user: Monitor64ProblemRowHow = "user"
        /// `api`: marked as resolved through the API.
        public static let api: Monitor64ProblemRowHow = "api"
        /// `removed`: the host or service was removed.
        public static let removed: Monitor64ProblemRowHow = "removed"
    }

    /// Status filter of the problem list.
    public struct Monitor64ProblemListStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `open` (server default)
        public static let open: Monitor64ProblemListStatus = "open"
        /// `closed`
        public static let closed: Monitor64ProblemListStatus = "closed"
        /// `all`
        public static let all: Monitor64ProblemListStatus = "all"
    }

    /// Time range filter of the problem list.
    public struct Monitor64ProblemListRange: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `6h`
        public static let sixHours: Monitor64ProblemListRange = "6h"
        /// `24h`
        public static let day: Monitor64ProblemListRange = "24h"
        /// `7d` (server default)
        public static let week: Monitor64ProblemListRange = "7d"
        /// `30d`
        public static let month: Monitor64ProblemListRange = "30d"
        /// `1y`
        public static let year: Monitor64ProblemListRange = "1y"
    }

    /// Action on an open problem.
    public struct Monitor64ProblemActionAction: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `ack`: acknowledge.
        public static let ack: Monitor64ProblemActionAction = "ack"
        /// `unack`: remove the acknowledgement.
        public static let unack: Monitor64ProblemActionAction = "unack"
        /// `comment`: add a comment (needs `comment`).
        public static let comment: Monitor64ProblemActionAction = "comment"
        /// `resolve`: mark as resolved.
        public static let resolve: Monitor64ProblemActionAction = "resolve"
    }

    /// Kind of target of an override.
    public struct Monitor64OverrideRowTargetType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `group`
        public static let group: Monitor64OverrideRowTargetType = "group"
        /// `tag`
        public static let tag: Monitor64OverrideRowTargetType = "tag"
    }

    /// Mode of a maintenance window.
    public struct Monitor64MaintInputMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `now`: from now on (`minutes`).
        public static let now: Monitor64MaintInputMode = "now"
        /// `plan`: `start` to `end`.
        public static let plan: Monitor64MaintInputMode = "plan"
        /// `recur`: recurring (`days`, `from`, `to`).
        public static let recur: Monitor64MaintInputMode = "recur"
    }

    /// State of a maintenance window.
    public struct Monitor64MaintenanceStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `running`
        public static let running: Monitor64MaintenanceStatus = "running"
        /// `planned`
        public static let planned: Monitor64MaintenanceStatus = "planned"
        /// `recurring`
        public static let recurring: Monitor64MaintenanceStatus = "recurring"
        /// `ended`
        public static let ended: Monitor64MaintenanceStatus = "ended"
    }

    /// Direction of moving an override (the topmost one wins).
    public enum Monitor64MoveDirection: Int, Codable, Hashable, Sendable {
        /// One place up.
        case up = -1
        /// One place down.
        case down = 1
    }
}

// MARK: - Problems

extension Node64 {
    /// A problem of a host or service.
    public struct Monitor64ProblemRow: Codable, Hashable, Sendable {
        /// UID of the problem.
        public let uid: String?
        /// UID of the host.
        public let hostUID: String?
        /// Service (empty = host not reachable).
        public let key: String?
        /// Current state.
        public let state: Monitor64ProblemRowState?
        /// Worst state.
        public let worst: String?
        /// When the problem opened.
        public let opened: Date?
        /// When it closed (`nil` while open).
        public let closed: Date?
        /// How it was closed.
        public let how: Monitor64ProblemRowHow?
        /// Who closed it.
        public let closedBy: Monitor64Actor?
        /// Acknowledgement.
        public let ack: Monitor64Ack?
        /// IDs of the channels it was reported to (`default` = default channels).
        public let notified: [String]?

        enum CodingKeys: String, CodingKey {
            case uid, key, state, worst, opened, closed, how, ack, notified
            case hostUID = "host_uid"
            case closedBy = "closed_by"
        }
    }

    /// A problem as listed: the row plus host name, service name, duration and channel names.
    public struct Monitor64Problem: Codable, Hashable, Sendable {
        /// UID of the problem.
        public let uid: String?
        /// UID of the host.
        public let hostUID: String?
        /// Service (empty = host not reachable).
        public let key: String?
        /// Current state.
        public let state: Monitor64ProblemRowState?
        /// Worst state.
        public let worst: String?
        /// When the problem opened.
        public let opened: Date?
        /// When it closed (`nil` while open).
        public let closed: Date?
        /// How it was closed.
        public let how: Monitor64ProblemRowHow?
        /// Who closed it.
        public let closedBy: Monitor64Actor?
        /// Acknowledgement.
        public let ack: Monitor64Ack?
        /// IDs of the channels it was reported to (`default` = default channels).
        public let notified: [String]?
        /// Name of the host (removed: its UID).
        public let host: String?
        /// The host was removed.
        public let hostGone: Bool?
        /// Name of the service.
        public let name: String?
        /// Duration in seconds (open: until now).
        public let duration: Int?
        /// Names of the channels.
        public let channels: [String]?

        enum CodingKeys: String, CodingKey {
            case uid, key, state, worst, opened, closed, how, ack, notified, host, name, duration, channels
            case hostUID = "host_uid"
            case closedBy = "closed_by"
            case hostGone = "host_gone"
        }
    }

    /// Result of the problem list.
    public struct Monitor64ProblemList: Codable, Hashable, Sendable {
        /// Problems, newest first (at most 5000).
        public let problems: [Monitor64Problem]?
        /// People involved (closing, acknowledging) for the `who` filter.
        public let people: [Monitor64Actor]?
        /// Counts in the range, without the other filters.
        public let counts: Counts?

        /// Counts of open and closed problems.
        public struct Counts: Codable, Hashable, Sendable {
            /// Open problems.
            public let open: Int?
            /// Closed problems.
            public let closed: Int?
        }
    }

    /// A problem with its history (`GET /monitor64/problems/{uid}`).
    public struct Monitor64ProblemDetail: Codable, Hashable, Sendable {
        /// The problem.
        public let problem: Monitor64ProblemRow?
        /// Its history.
        public let events: [Monitor64Event]?
        /// Channel ID to channel name.
        public let channels: [String: String]?
    }

    /// Acknowledge, comment on or resolve the open problem of a host and service.
    public struct Monitor64ProblemAction: Codable, Hashable, Sendable {
        /// UID of the host.
        public var host: String
        /// Service (empty or `nil` = the "not reachable" problem of the host).
        public var key: String?
        /// The action.
        public var action: Monitor64ProblemActionAction
        /// At most 500 characters; required for `comment`.
        public var comment: String?

        public init(host: String, key: String? = nil, action: Monitor64ProblemActionAction, comment: String? = nil) {
            self.host = host
            self.key = key
            self.action = action
            self.comment = comment
        }
    }
}

// MARK: - Rules

extension Node64 {
    /// Existing groups and tags of the hosts.
    public struct Monitor64Targets: Codable, Hashable, Sendable {
        /// Groups.
        public let groups: [String]?
        /// Tags.
        public let tags: [String]?
    }

    /// A kind of rule.
    public struct Monitor64RuleKind: Codable, Hashable, Sendable {
        /// The kind.
        public let kind: String?
        /// `system`, `storage`, `disks`, `network`, `devices` or `fixed`.
        public let group: String?
        /// Display unit.
        public let unit: String?
        /// Display value = value / factor.
        public let factor: Double?
        /// Fill level: also "GB free".
        public let store: Bool?
        /// State rule.
        public let state: Bool?
        /// Threshold downwards.
        public let down: Bool?
        /// Without duration.
        public let nofor: Bool?
    }

    /// Common fields of a stored override.
    public struct Monitor64OverrideRow: Codable, Hashable, Sendable {
        /// UID of the override.
        public let uid: String?
        /// Order (the topmost wins).
        public let position: Int?
        /// Group or tag.
        public let targetType: Monitor64OverrideRowTargetType?
        /// Name of the group or tag.
        public let target: String?
        /// Rule kind (thresholds only).
        public let kind: String?
        /// Stored rule or notification (free JSON).
        public let data: JSONValue?
        /// Who changed it.
        public let by: Monitor64Actor?
        /// When it changed.
        public let at: Date?

        enum CodingKeys: String, CodingKey {
            case uid, position, target, kind, data, by, at
            case targetType = "target_type"
        }
    }

    /// Effect of an override on the current state (without duration and hysteresis).
    public struct Monitor64Effect: Codable, Hashable, Sendable {
        /// Affected services.
        public let services: Int?
        /// Names of the affected hosts.
        public let hosts: [String]?
        /// Hosts where the threshold is set directly.
        public let own: [String]?
        /// Index of an override above it to hosts where it wins.
        public let shadow: [String: [String]]?
        /// Thresholds before.
        public let before: Thresholds?
        /// Thresholds after.
        public let after: Thresholds?

        /// Warning and critical threshold.
        public struct Thresholds: Codable, Hashable, Sendable {
            /// Warning.
            public let warn: Int?
            /// Critical.
            public let crit: Int?
        }
    }

    /// A threshold override for a group or tag.
    public struct Monitor64RuleOverride: Codable, Hashable, Sendable {
        /// UID of the override.
        public let uid: String?
        /// Order (the topmost wins).
        public let position: Int?
        /// Group or tag.
        public let targetType: Monitor64OverrideRowTargetType?
        /// Name of the group or tag.
        public let target: String?
        /// Rule kind.
        public let kind: String?
        /// Stored rule (free JSON).
        public let data: JSONValue?
        /// Who changed it.
        public let by: Monitor64Actor?
        /// When it changed.
        public let at: Date?
        /// The rule.
        public let rule: Monitor64Rule?
        /// Its effect on the current state.
        public let effect: Monitor64Effect?

        enum CodingKeys: String, CodingKey {
            case uid, position, target, kind, data, by, at, rule, effect
            case targetType = "target_type"
        }
    }

    /// Thresholds set on a host.
    public struct Monitor64OwnRule: Codable, Hashable, Sendable {
        /// UID of the host.
        public let hostUID: String?
        /// Name of the host.
        public let host: String?
        /// Service (empty = all services of the host with this kind).
        public let key: String?
        /// Name of the service.
        public let name: String?
        /// Rule kind.
        public let kind: String?
        /// The rule.
        public let rule: Monitor64Rule?

        enum CodingKeys: String, CodingKey {
            case host, key, name, kind, rule
            case hostUID = "host_uid"
        }
    }

    /// Thresholds (`GET /monitor64/rules`).
    public struct Monitor64Rules: Codable, Hashable, Sendable {
        /// Rule kinds.
        public let kinds: [Monitor64RuleKind]?
        /// Built-in default per kind.
        public let defaults: [String: Monitor64Rule]?
        /// Effective default table (built-in plus changes).
        public let std: [String: Monitor64Rule]?
        /// Overrides per group or tag, topmost first.
        public let overrides: [Monitor64RuleOverride]?
        /// Thresholds set on hosts.
        public let own: [Monitor64OwnRule]?
        /// Existing groups and tags.
        public let targets: Monitor64Targets?
    }

    /// Create or replace a threshold override.
    public struct Monitor64RuleOverrideInput: Codable, Hashable, Sendable {
        /// Group or tag.
        public var targetType: Monitor64OverrideRowTargetType
        /// Group or tag name (at most 64 characters; tags lowercase).
        public var target: String
        /// Rule kind from the default table.
        public var kind: String
        /// The rule; needs at least one field (otherwise 400 `rule_empty`).
        public var rule: Monitor64Rule

        public init(targetType: Monitor64OverrideRowTargetType, target: String, kind: String, rule: Monitor64Rule) {
            self.targetType = targetType
            self.target = target
            self.kind = kind
            self.rule = rule
        }

        enum CodingKeys: String, CodingKey {
            case target, kind, rule
            case targetType = "target_type"
        }
    }

    /// Result of saving the default table.
    public struct Monitor64RuleStdResult: Codable, Hashable, Sendable {
        /// Always `true`.
        public let ok: Bool?
        /// Saved kinds.
        public let changed: [String]?
    }
}

// MARK: - Notification

extension Node64 {
    /// A notification channel of the node (without configuration and secrets).
    public struct Monitor64Channel: Codable, Hashable, Sendable {
        /// Channel ID.
        public let id: Int?
        /// Channel type.
        public let type: String?
        /// Name.
        public let name: String?
        /// Switched on.
        public let enabled: Bool?
        /// Default channel.
        public let isDefault: Bool?

        enum CodingKeys: String, CodingKey {
            case id, type, name, enabled
            case isDefault = "default"
        }
    }

    /// A channel with severity; entries with neither `warn` nor `crit` are dropped.
    public struct Monitor64ChannelRoute: Codable, Hashable, Sendable {
        /// `default` = default channels of Node64, otherwise the ID of a node channel as text.
        public var id: String
        /// Report on warning.
        public var warn: Bool?
        /// Report on critical.
        public var crit: Bool?

        public init(id: String, warn: Bool? = nil, crit: Bool? = nil) {
            self.id = id
            self.warn = warn
            self.crit = crit
        }
    }

    /// Basic notification settings.
    public struct Monitor64NotifyConfig: Codable, Hashable, Sendable {
        /// Channels by severity. Channels without warn and crit are dropped, duplicates count once.
        public var channels: [Monitor64ChannelRoute]?
        /// Reminder on warning in seconds (0 = never, otherwise at least 3600).
        public var remindWarn: Int?
        /// Reminder on critical in seconds (0 = never, otherwise at least 3600; default daily).
        public var remindCrit: Int?
        /// Report critical immediately in quiet hours too.
        public var critInQuiet: Bool?

        public init(
            channels: [Monitor64ChannelRoute]? = nil,
            remindWarn: Int? = nil,
            remindCrit: Int? = nil,
            critInQuiet: Bool? = nil
        ) {
            self.channels = channels
            self.remindWarn = remindWarn
            self.remindCrit = remindCrit
            self.critInQuiet = critInQuiet
        }

        enum CodingKeys: String, CodingKey {
            case channels
            case remindWarn = "remind_warn"
            case remindCrit = "remind_crit"
            case critInQuiet = "crit_in_quiet"
        }
    }

    /// Stored notification override; missing fields inherit.
    public struct Monitor64NotifyOverrideData: Codable, Hashable, Sendable {
        /// Channels.
        public let channels: [Monitor64ChannelRoute]?
        /// `true`: channels instead of the basic settings, `false`: in addition.
        public let replace: Bool?
        /// Report critical only.
        public let onlyCrit: Bool?
        /// Report critical in quiet hours.
        public let critInQuiet: Bool?
        /// Reminder on warning in seconds.
        public let remindWarn: Int?
        /// Reminder on critical in seconds.
        public let remindCrit: Int?

        enum CodingKeys: String, CodingKey {
            case channels, replace
            case onlyCrit = "only_crit"
            case critInQuiet = "crit_in_quiet"
            case remindWarn = "remind_warn"
            case remindCrit = "remind_crit"
        }
    }

    /// A notification override for a group or tag.
    public struct Monitor64NotifyOverride: Codable, Hashable, Sendable {
        /// UID of the override.
        public let uid: String?
        /// Order (the topmost wins).
        public let position: Int?
        /// Group or tag.
        public let targetType: Monitor64OverrideRowTargetType?
        /// Name of the group or tag.
        public let target: String?
        /// Rule kind (thresholds only).
        public let kind: String?
        /// Stored notification (free JSON).
        public let data: JSONValue?
        /// Who changed it.
        public let by: Monitor64Actor?
        /// When it changed.
        public let at: Date?
        /// The notification settings.
        public let notify: Monitor64NotifyOverrideData?

        enum CodingKeys: String, CodingKey {
            case uid, position, target, kind, data, by, at, notify
            case targetType = "target_type"
        }
    }

    /// Notification settings (`GET /monitor64/notify`).
    public struct Monitor64Notify: Codable, Hashable, Sendable {
        /// Basic settings.
        public let config: Monitor64NotifyConfig?
        /// Channels of the node.
        public let channels: [Monitor64Channel]?
        /// Overrides per group or tag, topmost first.
        public let overrides: [Monitor64NotifyOverride]?
        /// Quiet hours.
        public let quiet: Quiet?
        /// Existing groups and tags.
        public let targets: Monitor64Targets?

        /// Quiet hours from the notification settings of the node (read-only).
        public struct Quiet: Codable, Hashable, Sendable {
            /// Switched on.
            public let enabled: Bool?
            /// Start.
            public let from: String?
            /// End.
            public let to: String?
            /// Days.
            public let days: String?
        }
    }

    /// Create or replace a notification override. A `nil` field is not sent and inherits.
    public struct Monitor64NotifyOverrideInput: Codable, Hashable, Sendable {
        /// Group or tag.
        public var targetType: Monitor64OverrideRowTargetType
        /// Group or tag name (at most 64 characters; tags lowercase).
        public var target: String
        /// Channels.
        public var channels: [Monitor64ChannelRoute]?
        /// `true`: channels instead of the basic settings, `false`: in addition.
        public var replace: Bool?
        /// Report critical only.
        public var onlyCrit: Bool?
        /// Report critical in quiet hours.
        public var critInQuiet: Bool?
        /// Reminder on warning in seconds (0 = never, otherwise at least 3600).
        public var remindWarn: Int?
        /// Reminder on critical in seconds (0 = never, otherwise at least 3600).
        public var remindCrit: Int?

        public init(
            targetType: Monitor64OverrideRowTargetType,
            target: String,
            channels: [Monitor64ChannelRoute]? = nil,
            replace: Bool? = nil,
            onlyCrit: Bool? = nil,
            critInQuiet: Bool? = nil,
            remindWarn: Int? = nil,
            remindCrit: Int? = nil
        ) {
            self.targetType = targetType
            self.target = target
            self.channels = channels
            self.replace = replace
            self.onlyCrit = onlyCrit
            self.critInQuiet = critInQuiet
            self.remindWarn = remindWarn
            self.remindCrit = remindCrit
        }

        enum CodingKeys: String, CodingKey {
            case target, channels, replace
            case targetType = "target_type"
            case onlyCrit = "only_crit"
            case critInQuiet = "crit_in_quiet"
            case remindWarn = "remind_warn"
            case remindCrit = "remind_crit"
        }
    }

    /// Result of the test notification.
    public struct Monitor64NotifyTestResult: Codable, Hashable, Sendable {
        /// Success.
        public let ok: Bool?
        /// Number of channels.
        public let channels: Int?
    }
}

// MARK: - Maintenance

extension Node64 {
    /// A maintenance window.
    public struct Monitor64Maintenance: Codable, Hashable, Sendable {
        /// UID.
        public let uid: String?
        /// Title.
        public let title: String?
        /// Host UIDs.
        public let hosts: [String]?
        /// Groups.
        public let groups: [String]?
        /// Tags.
        public let tags: [String]?
        /// Start.
        public let start: Date?
        /// End.
        public let end: Date?
        /// Recurrence.
        public let recur: Monitor64Recurrence?
        /// Ended by hand.
        public let ended: Date?
        /// Who created it.
        public let by: Monitor64Actor?
        /// When it was created.
        public let at: Date?
        /// Who changed it last.
        public let changedBy: Monitor64Actor?
        /// State.
        public let status: Monitor64MaintenanceStatus?
        /// Active right now.
        public let running: Bool?
        /// Start in the time zone of the node (`YYYY-MM-DDTHH:MM`).
        public let startLocal: String?
        /// End in the time zone of the node.
        public let endLocal: String?
        /// Hand-ended time in the time zone of the node.
        public let endedLocal: String?

        enum CodingKeys: String, CodingKey {
            case uid, title, hosts, groups, tags, start, end, recur, ended, by, at, status, running
            case changedBy = "changed_by"
            case startLocal = "start_local"
            case endLocal = "end_local"
            case endedLocal = "ended_local"
        }
    }

    /// Maintenance windows and choices (`GET /monitor64/maintenance`).
    public struct Monitor64MaintList: Codable, Hashable, Sendable {
        /// Windows.
        public let items: [Monitor64Maintenance]?
        /// Hosts to choose from.
        public let hosts: [Host]?
        /// Groups and tags to choose from.
        public let targets: Monitor64Targets?
        /// Time zone of the node.
        public let tz: String?
        /// Now in the time zone of the node.
        public let nowLocal: String?

        /// A host to choose from.
        public struct Host: Codable, Hashable, Sendable {
            /// UID.
            public let uid: String?
            /// Name.
            public let name: String?
            /// Group.
            public let group: String?
            /// Kind.
            public let kind: String?
        }

        enum CodingKeys: String, CodingKey {
            case items, hosts, targets, tz
            case nowLocal = "now_local"
        }
    }

    /// Create or replace a maintenance window; needs at least one host, group or tag.
    /// Recurring windows apply from saving on (not retroactively).
    public struct Monitor64MaintInput: Codable, Hashable, Sendable {
        /// Title (at most 200 characters).
        public var title: String?
        /// UIDs of existing hosts.
        public var hosts: [String]?
        /// Groups.
        public var groups: [String]?
        /// Tags.
        public var tags: [String]?
        /// `now`, `plan` or `recur`.
        public var mode: Monitor64MaintInputMode
        /// now: duration in minutes (0 = until ended, at most 43200).
        public var minutes: Int?
        /// plan: start `YYYY-MM-DDTHH:MM` in the time zone of the node.
        public var start: String?
        /// plan: end `YYYY-MM-DDTHH:MM` (after the start).
        public var end: String?
        /// recur: weekdays, 0 = Sunday; empty = every day.
        public var days: [Int]?
        /// recur: `HH:MM`.
        public var from: String?
        /// recur: `HH:MM` (up to 24:00).
        public var to: String?

        public init(
            title: String? = nil,
            hosts: [String]? = nil,
            groups: [String]? = nil,
            tags: [String]? = nil,
            mode: Monitor64MaintInputMode,
            minutes: Int? = nil,
            start: String? = nil,
            end: String? = nil,
            days: [Int]? = nil,
            from: String? = nil,
            to: String? = nil
        ) {
            self.title = title
            self.hosts = hosts
            self.groups = groups
            self.tags = tags
            self.mode = mode
            self.minutes = minutes
            self.start = start
            self.end = end
            self.days = days
            self.from = from
            self.to = to
        }
    }
}
