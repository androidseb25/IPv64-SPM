import Foundation

extension Node64 {
    /// Trust level of a Sonar64 node.
    public struct Sonar64TrustLevel: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `new`
        public static let new: Sonar64TrustLevel = "new"
        /// `stable`
        public static let stable: Sonar64TrustLevel = "stable"
        /// `trusted`
        public static let trusted: Sonar64TrustLevel = "trusted"
        /// `pillar`
        public static let pillar: Sonar64TrustLevel = "pillar"
        /// `anchor`
        public static let anchor: Sonar64TrustLevel = "anchor"
        /// `quarantine`
        public static let quarantine: Sonar64TrustLevel = "quarantine"
    }

    /// Why a Sonar64 node pauses measuring.
    public struct Sonar64PauseReason: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `uplink`
        public static let uplink: Sonar64PauseReason = "uplink"
        /// `quiet`
        public static let quiet: Sonar64PauseReason = "quiet"
        /// `no_plan`
        public static let noPlan: Sonar64PauseReason = "no_plan"
        /// `budget`
        public static let budget: Sonar64PauseReason = "budget"
    }

    /// Measurement method of Sonar64.
    public struct Sonar64Method: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `icmp`
        public static let icmp: Sonar64Method = "icmp"
        /// `udp`
        public static let udp: Sonar64Method = "udp"
        /// `trace`
        public static let trace: Sonar64Method = "trace"
    }

    /// Measurement budget of a Sonar64 node.
    public struct Sonar64Budget: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `sparsam`
        public static let sparing: Sonar64Budget = "sparsam"
        /// `normal`
        public static let normal: Sonar64Budget = "normal"
        /// `grosszuegig`
        public static let generous: Sonar64Budget = "grosszuegig"
    }

    /// Connection type of a Sonar64 node.
    public struct Sonar64Access: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `fiber`
        public static let fiber: Sonar64Access = "fiber"
        /// `dsl`
        public static let dsl: Sonar64Access = "dsl"
        /// `cable`
        public static let cable: Sonar64Access = "cable"
        /// `mobile`
        public static let mobile: Sonar64Access = "mobile"
        /// `satellite`
        public static let satellite: Sonar64Access = "satellite"
        /// `datacenter`
        public static let datacenter: Sonar64Access = "datacenter"
        /// `other`
        public static let other: Sonar64Access = "other"
        /// Empty: not set (only in responses).
        public static let unset: Sonar64Access = ""
    }

    /// Device type of a Sonar64 node.
    public struct Sonar64Device: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `node64`
        public static let node64: Sonar64Device = "node64"
        /// `pi`
        public static let pi: Sonar64Device = "pi"
        /// `mikrotik`
        public static let mikrotik: Sonar64Device = "mikrotik"
        /// `linux`
        public static let linux: Sonar64Device = "linux"
        /// `other`
        public static let other: Sonar64Device = "other"
        /// Empty: not set (only in responses).
        public static let unset: Sonar64Device = ""
    }

    /// Result of ``Node64/Sonar64/status()``.
    ///
    /// Schema `Sonar64Status`.
    public struct Sonar64Status: Codable, Hashable, Sendable {
        /// Software version of the module.
        public let version: String?
        /// The module is running.
        public let running: Bool?
        /// Start time.
        public let startedAt: Date?
        /// A central ipv64 API key is stored.
        public let keySet: Bool?
        /// The node takes part in Sonar64.
        public let participate: Bool?
        /// State of the node (core); empty without participation.
        public let node: Sonar64NodeState?
        /// Error message.
        public let error: String?
        /// UDP 6464 is in use: outgoing only.
        public let portError: String?
        /// The own node at ipv64 (`GET /sonar/me`, free-form), including the exact location. `nil` when unknown.
        public let me: JSONValue?
        /// Error while fetching ``me``.
        public let meError: String?
        /// Trust level.
        public let trust: Sonar64Trust?
        /// Public node page on ipv64.net.
        public let publicURL: String?

        enum CodingKeys: String, CodingKey {
            case version, running, participate, node, error, me, trust
            case startedAt = "started_at"
            case keySet = "key_set"
            case portError = "port_error"
            case meError = "me_error"
            case publicURL = "public_url"
        }
    }

    /// The `node` object of ``Sonar64Status``.
    public struct Sonar64NodeState: Codable, Hashable, Sendable {
        /// Node ID.
        public let nodeID: String?
        /// The node is registered at ipv64.
        public let registered: Bool?
        /// Mode.
        public let mode: String?
        /// The node is measured too (UDP 6464 open).
        public let measured: Bool?
        /// Budget.
        public let budget: String?
        /// The node answers probes.
        public let responder: Bool?
        /// Issue time of the measurement plan.
        public let planIssued: Date?
        /// Expiry of the measurement plan.
        public let planExpires: Date?
        /// Only anchors are measured.
        public let anchorsOnly: Bool?
        /// Why measuring is paused.
        public let paused: Sonar64PauseReason?
        /// Probes sent today.
        public let sentToday: Int?
        /// Time of the last report.
        public let lastReport: Date?
        /// Results waiting to be reported.
        public let buffered: Int?
        /// Last error.
        public let lastError: String?

        enum CodingKeys: String, CodingKey {
            case registered, mode, measured, budget, responder, paused, buffered
            case nodeID = "node_id"
            case planIssued = "plan_issued"
            case planExpires = "plan_expires"
            case anchorsOnly = "anchors_only"
            case sentToday = "sent_today"
            case lastReport = "last_report"
            case lastError = "last_error"
        }
    }

    /// The `trust` object of ``Sonar64Status``.
    public struct Sonar64Trust: Codable, Hashable, Sendable {
        /// Level.
        public let level: Sonar64TrustLevel?
        /// Class.
        public let `class`: String?
        /// Next level.
        public let next: String?
        /// Progress to the next level in percent.
        public let pct: Int?
        /// Days of participation.
        public let days: Int?
        /// Days needed for the next level.
        public let needDays: Int?
        /// Uptime.
        public let uptime: Double?
        /// Uptime needed for the next level.
        public let needUptime: Double?
        /// Being measured is needed for the next level.
        public let needMeasured: Bool?

        enum CodingKeys: String, CodingKey {
            case level, `class`, next, pct, days, uptime
            case needDays = "need_days"
            case needUptime = "need_uptime"
            case needMeasured = "need_measured"
        }
    }

    /// Result of ``Node64/Sonar64/recent(n:)``.
    ///
    /// Schema `Sonar64Recent`.
    public struct Sonar64Recent: Codable, Hashable, Sendable {
        /// Own measurements, newest first.
        public let results: [Sonar64Result]?
        /// Probes answered live on UDP 6464.
        public let inbound: [Sonar64InboundProbe]?
        /// The node answers probes.
        public let responder: Bool?
    }

    /// An own measurement in ``Sonar64Recent``.
    public struct Sonar64Result: Codable, Hashable, Sendable {
        /// Time of the measurement.
        public let at: Date?
        /// Node ID of the target (anchor `a_<name>`).
        public let target: String?
        /// Method.
        public let method: Sonar64Method?
        /// IP family (4 or 6).
        public let fam: Int?
        /// Probes sent.
        public let sent: Int?
        /// Probes received.
        public let recv: Int?
        /// Minimum round-trip time.
        public let min: Double?
        /// Average round-trip time.
        public let avg: Double?
        /// Maximum round-trip time.
        public let max: Double?
        /// Loss in percent.
        public let loss: Double?
        /// Error.
        public let err: String?
    }

    /// A probe answered live in ``Sonar64Recent``.
    public struct Sonar64InboundProbe: Codable, Hashable, Sendable {
        /// Short ID (8 hex characters) of the measuring node.
        public let from: String?
        /// Name of the measuring node.
        public let name: String?
        /// IP family (4 or 6).
        public let fam: Int?
        /// Number of probes.
        public let count: Int?
        /// Time of the last probe.
        public let at: Date?
    }

    /// Result of ``Node64/Sonar64/inbound(since:)``.
    ///
    /// Schema `Sonar64Inbound`.
    public struct Sonar64Inbound: Codable, Hashable, Sendable {
        /// `false` while the node is not registered.
        public let ready: Bool?
        /// Measurements of this node by others (at most 500).
        public let rows: [Sonar64InboundRow]?
    }

    /// A row of ``Sonar64Inbound``.
    public struct Sonar64InboundRow: Codable, Hashable, Sendable {
        /// ID of the measuring node.
        public let from: String?
        /// Name of the measuring node.
        public let name: String?
        /// AS name.
        public let asname: String?
        /// Place.
        public let place: String?
        /// Trust level of the measuring node.
        public let trust: Sonar64TrustLevel?
        /// IP family (4 or 6).
        public let fam: Int?
        /// Method.
        public let method: String?
        /// Average round-trip time.
        public let avg: Double?
        /// Loss as a fraction from 0 to 1.
        public let loss: Double?
        /// Time of the measurement.
        public let at: Date?
    }

    /// Result of ``Node64/Sonar64/settings()``.
    ///
    /// Schema `Sonar64Settings`.
    public struct Sonar64Settings: Codable, Hashable, Sendable {
        /// The node takes part.
        public let participate: Bool?
        /// The node is measured too (UDP 6464).
        public let measured: Bool?
        /// Budget.
        public let budget: Sonar64Budget?
        /// Quiet hours `from-to` in hours, e.g. `23-6`; empty = none.
        public let quiet: String?
        /// Name of the node.
        public let name: String?
        /// Latitude.
        public let lat: Double?
        /// Longitude.
        public let lon: Double?
        /// Connection type.
        public let access: Sonar64Access?
        /// Device type.
        public let device: Sonar64Device?
    }

    /// Body of ``Node64/Sonar64/updateSettings(_:)``. Omitted (`nil`) fields stay unchanged.
    ///
    /// Schema `Sonar64SettingsPut`.
    public struct Sonar64SettingsInput: Codable, Hashable, Sendable {
        /// Take part or leave.
        public var participate: Bool?
        /// Also be measured (opens UDP 6464).
        public var measured: Bool?
        /// Budget.
        public var budget: Sonar64Budget?
        /// Quiet hours `from-to`, e.g. `23-6`.
        public var quiet: String?
        /// Name of the node.
        public var name: String?
        /// Latitude.
        public var lat: Double?
        /// Longitude.
        public var lon: Double?
        /// Delete the location.
        public var clearLocation: Bool?
        /// Connection type.
        public var access: Sonar64Access?
        /// Device type.
        public var device: Sonar64Device?

        /// Creates a settings change; pass only the fields to change.
        public init(
            participate: Bool? = nil, measured: Bool? = nil, budget: Sonar64Budget? = nil, quiet: String? = nil,
            name: String? = nil, lat: Double? = nil, lon: Double? = nil, clearLocation: Bool? = nil,
            access: Sonar64Access? = nil, device: Sonar64Device? = nil
        ) {
            self.participate = participate
            self.measured = measured
            self.budget = budget
            self.quiet = quiet
            self.name = name
            self.lat = lat
            self.lon = lon
            self.clearLocation = clearLocation
            self.access = access
            self.device = device
        }

        enum CodingKeys: String, CodingKey {
            case participate, measured, budget, quiet, name, lat, lon, access, device
            case clearLocation = "clear_location"
        }
    }
}
