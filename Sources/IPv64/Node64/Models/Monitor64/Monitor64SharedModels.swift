import Foundation

extension Node64 {
    /// State of a host, service or metric.
    public struct Monitor64State: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `ok`
        public static let ok: Monitor64State = "ok"
        /// `warn`
        public static let warn: Monitor64State = "warn"
        /// `crit`
        public static let crit: Monitor64State = "crit"
        /// `unknown`
        public static let unknown: Monitor64State = "unknown"
    }

    /// Overview state of a host: maintenance beats unreachable beats the worst service.
    public struct Monitor64View: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `ok`
        public static let ok: Monitor64View = "ok"
        /// `warn`
        public static let warn: Monitor64View = "warn"
        /// `crit`
        public static let crit: Monitor64View = "crit"
        /// `unknown`
        public static let unknown: Monitor64View = "unknown"
        /// `unreachable`
        public static let unreachable: Monitor64View = "unreachable"
        /// `maintenance`
        public static let maintenance: Monitor64View = "maintenance"
    }

    /// Kind of an actor.
    public struct Monitor64ActorKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `user`
        public static let user: Monitor64ActorKind = "user"
        /// `api`
        public static let api: Monitor64ActorKind = "api"
        /// `system`
        public static let system: Monitor64ActorKind = "system"
    }

    /// Quantity of a meter.
    public struct Monitor64MeterLabel: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `cpu`
        public static let cpu: Monitor64MeterLabel = "cpu"
        /// `ram`
        public static let ram: Monitor64MeterLabel = "ram"
        /// `disk`
        public static let disk: Monitor64MeterLabel = "disk"
    }

    /// Direction of a numeric rule: `up` is a problem from the threshold upwards (usage), `down` below it (toner, UPS runtime).
    public struct Monitor64RuleDir: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `up`
        public static let up: Monitor64RuleDir = "up"
        /// `down`
        public static let down: Monitor64RuleDir = "down"
    }

    /// Mode of a numeric rule: `used` compares percent used, `free` compares GB free.
    public struct Monitor64RuleMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `used`
        public static let used: Monitor64RuleMode = "used"
        /// `free`
        public static let free: Monitor64RuleMode = "free"
    }

    /// Whether a rule notifies or only shows.
    public struct Monitor64RuleReport: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `notify`
        public static let notify: Monitor64RuleReport = "notify"
        /// `show`
        public static let show: Monitor64RuleReport = "show"
    }

    /// Severity of a state rule (`off` = do not report).
    public struct Monitor64RuleSeverity: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `crit`
        public static let crit: Monitor64RuleSeverity = "crit"
        /// `warn`
        public static let warn: Monitor64RuleSeverity = "warn"
        /// `off`
        public static let off: Monitor64RuleSeverity = "off"
    }

    /// Threshold: a number or `"off"` (explicitly no threshold, e.g. "critical only").
    public enum Monitor64Limit: Codable, Hashable, Sendable {
        /// A numeric threshold.
        case value(Double)
        /// Explicitly no threshold (`"off"`).
        case off

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let number = try? container.decode(Double.self) {
                self = .value(number)
            } else if try container.decode(String.self) == "off" {
                self = .off
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a number or \"off\"")
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .value(let number): try container.encode(number)
            case .off: try container.encode("off")
            }
        }
    }

    /// Who triggered a change or action.
    public struct Monitor64Actor: Codable, Hashable, Sendable {
        /// Person, API key or system.
        public let kind: Monitor64ActorKind?

        /// Cluster-wide user UID (people).
        public let uid: String?

        /// Name at the time of the action (user or name of the API key).
        public let name: String?

        /// Sign-in method of people (currently always `local`).
        public let method: String?

        /// Address of the caller.
        public let ip: String?

        enum CodingKeys: String, CodingKey {
            case kind
            case uid
            case name
            case method
            case ip
        }
    }

    /// Acknowledgement.
    public struct Monitor64Ack: Codable, Hashable, Sendable {
        /// Who acknowledged.
        public let by: Monitor64Actor?

        /// When.
        public let at: Date?

        /// Comment.
        public let comment: String?

        enum CodingKeys: String, CodingKey {
            case by
            case at
            case comment
        }
    }

    /// Entry in the timeline of a problem.
    public struct Monitor64Event: Codable, Hashable, Sendable {
        /// Time of the entry.
        public let at: Date?

        /// Kind, e.g. a state (`warn`, `crit`, ...), `ok`, `ack`, `unack`, `comment`, `resolved`, `bell`, `maint`, `maint_end`, `pause`, `resume`, `takeover`, `handover`, `agent_update`.
        public let kind: String?

        /// Text.
        public let text: String?

        /// Who caused it.
        public let actor: Monitor64Actor?

        /// UID of the host.
        public let hostUID: String?

        /// Key of the service.
        public let key: String?

        /// UID of the problem.
        public let problem: String?

        enum CodingKeys: String, CodingKey {
            case at
            case kind
            case text
            case actor
            case hostUID = "host_uid"
            case key
            case problem
        }
    }

    /// A small usage meter of a host.
    public struct Monitor64Meter: Codable, Hashable, Sendable {
        /// Quantity.
        public let label: Monitor64MeterLabel?

        /// Percent.
        public let value: Double?

        /// State.
        public let state: Monitor64State?

        enum CodingKeys: String, CodingKey {
            case label
            case value
            case state
        }
    }

    /// Plain acknowledgement `{"ok": true}`.
    public struct Monitor64Ok: Codable, Hashable, Sendable {
        /// Always `true`.
        public let ok: Bool?

        enum CodingKeys: String, CodingKey {
            case ok
        }
    }

    /// Host on the overview.
    public struct Monitor64OverviewHost: Codable, Hashable, Sendable {
        /// UID of the host.
        public let uid: String?

        /// Name.
        public let name: String?

        /// Address.
        public let address: String?

        /// Kind of the host.
        public let kind: String?

        /// Bootstrap icon.
        public let icon: String?

        /// Group.
        public let group: String?

        /// Tags.
        public let tags: [String]?

        /// State.
        public let state: Monitor64State?

        /// View: maintenance > unreachable > worst service.
        public let view: Monitor64View?

        /// Open problems.
        public let problems: Int?

        /// Number of services.
        public let services: Int?

        /// Newly detected services.
        public let new: Int?

        /// Vanished services.
        public let vanished: Int?

        /// Queries are paused.
        public let paused: Bool?

        /// Running maintenance.
        public let maint: Maintenance?

        /// Error of the accesses when unreachable.
        public let unreach: String?

        /// Meters.
        public let meters: [Monitor64Meter]?

        /// Text.
        public let text: String?

        /// CPU percent.
        public let cpu: Double?

        /// RAM percent.
        public let ram: Double?

        /// CPU value present.
        public let hasCpu: Bool?

        /// RAM value present.
        public let hasRam: Bool?

        /// Last round.
        public let checked: Date?

        /// Running maintenance.
        public struct Maintenance: Codable, Hashable, Sendable {
            /// Reason.
            public let reason: String?

            /// End of the maintenance.
            public let end: Date?

            enum CodingKeys: String, CodingKey {
                case reason
                case end
            }
        }

        enum CodingKeys: String, CodingKey {
            case uid
            case name
            case address
            case kind
            case icon
            case group
            case tags
            case state
            case view
            case problems
            case services
            case new
            case vanished
            case paused
            case maint
            case unreach
            case meters
            case text
            case cpu
            case ram
            case hasCpu = "has_cpu"
            case hasRam = "has_ram"
            case checked
        }
    }

    /// Weekly recurrence of a maintenance window.
    public struct Monitor64Recurrence: Codable, Hashable, Sendable {
        /// Weekdays, 0 = Sunday; empty = every day.
        public let days: [Int]?

        /// Start `HH:MM`.
        public let from: String?

        /// End `HH:MM`.
        public let to: String?

        enum CodingKeys: String, CodingKey {
            case days
            case from
            case to
        }
    }

    /// Rule of one level. Missing fields inherit field by field from the level below (default, deviation for group/tag, this host for all services of the kind, only this service). Number rules use `warn`/`crit` (or `warn_free`/`crit_free`), `dir`, `forSeconds`, `hyst` and `mode`; state rules use `severity` and `forSeconds`; `report` applies to both. Used as response and as input, `nil` fields are not sent.
    public struct Monitor64Rule: Codable, Hashable, Sendable {
        /// Warning threshold (percent or value).
        public var warn: Monitor64Limit?

        /// Critical threshold.
        public var crit: Monitor64Limit?

        /// Warning in GB free (mode `free`).
        public var warnFree: Monitor64Limit?

        /// Critical in GB free (mode `free`).
        public var critFree: Monitor64Limit?

        /// Direction.
        public var dir: Monitor64RuleDir?

        /// Duration in seconds (0 to 31622400): all measurements in the period must be beyond the threshold.
        public var forSeconds: Int?

        /// Hysteresis in units of the value (not negative).
        public var hyst: Double?

        /// Mode.
        public var mode: Monitor64RuleMode?

        /// Notify or only show.
        public var report: Monitor64RuleReport?

        /// Severity of a state rule.
        public var severity: Monitor64RuleSeverity?

        /// Creates the value; pass only what you want to send.
        public init(
            warn: Monitor64Limit? = nil,
            crit: Monitor64Limit? = nil,
            warnFree: Monitor64Limit? = nil,
            critFree: Monitor64Limit? = nil,
            dir: Monitor64RuleDir? = nil,
            forSeconds: Int? = nil,
            hyst: Double? = nil,
            mode: Monitor64RuleMode? = nil,
            report: Monitor64RuleReport? = nil,
            severity: Monitor64RuleSeverity? = nil
        ) {
            self.warn = warn
            self.crit = crit
            self.warnFree = warnFree
            self.critFree = critFree
            self.dir = dir
            self.forSeconds = forSeconds
            self.hyst = hyst
            self.mode = mode
            self.report = report
            self.severity = severity
        }

        enum CodingKeys: String, CodingKey {
            case warn
            case crit
            case warnFree = "warn_free"
            case critFree = "crit_free"
            case dir
            case forSeconds = "for"
            case hyst
            case mode
            case report
            case severity
        }
    }

    /// State of the SNMP trap receiver.
    public struct Monitor64TrapStatus: Codable, Hashable, Sendable {
        /// Hosts with traps.
        public let active: Int?

        /// Receiver runs.
        public let running: Bool?

        /// Port.
        public let port: Int?

        /// Engine ID.
        public let engineID: String?

        /// Error text.
        public let error: String?

        /// Counters.
        public let stats: Stats?

        /// Unknown senders, newest first.
        public let unknown: [UnknownSender]?

        /// Counters of the trap receiver.
        public struct Stats: Codable, Hashable, Sendable {
            /// Received.
            public let received: Int?

            /// Accepted.
            public let accepted: Int?

            /// Too big.
            public let tooBig: Int?

            /// Rate limited.
            public let rateLimited: Int?

            /// Bad packets.
            public let badPacket: Int?

            /// Rejected.
            public let rejected: Int?

            /// From unknown senders.
            public let unknown: Int?

            /// Dropped, queue full.
            public let queueFull: Int?

            enum CodingKeys: String, CodingKey {
                case received
                case accepted
                case tooBig = "too_big"
                case rateLimited = "rate_limited"
                case badPacket = "bad_packet"
                case rejected
                case unknown
                case queueFull = "queue_full"
            }
        }

        /// Unknown sender of traps.
        public struct UnknownSender: Codable, Hashable, Sendable {
            /// Address.
            public let addr: String?

            /// First seen.
            public let first: Date?

            /// Last seen.
            public let last: Date?

            /// Number of traps.
            public let count: Int?

            /// SNMP version.
            public let version: String?

            /// Trap OID.
            public let trapOID: String?

            /// Trap name.
            public let trapName: String?

            /// SNMPv3 user.
            public let user: String?

            enum CodingKeys: String, CodingKey {
                case addr
                case first
                case last
                case count
                case version
                case trapOID = "trap_oid"
                case trapName = "trap_name"
                case user
            }
        }

        enum CodingKeys: String, CodingKey {
            case active
            case running
            case port
            case engineID = "engine_id"
            case error
            case stats
            case unknown
        }
    }
}
