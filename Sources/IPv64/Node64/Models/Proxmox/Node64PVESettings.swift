import Foundation

extension Node64 {
    /// Schema `PVEThreshold`: a threshold rule.
    public struct PVEThreshold: Codable, Hashable, Sendable {
        /// Percent; `0` switches the rule off.
        public var percent: Double?
        /// Minutes the value has to stay above the threshold.
        public var minutes: Int?

        public init(percent: Double? = nil, minutes: Int? = nil) {
            self.percent = percent
            self.minutes = minutes
        }
    }

    /// Schema `PVERuleSet`: rules of one level. Missing fields are inherited (system, node, guest).
    public struct PVERuleSet: Codable, Hashable, Sendable {
        /// Report crashed guests.
        public var crashed: Bool?
        /// Report stopped guests.
        public var stopped: Bool?
        /// Report paused guests.
        public var paused: Bool?
        /// Report suspended guests.
        public var suspended: Bool?
        /// Report offline nodes.
        public var offline: Bool?
        /// Report an unreachable system.
        public var unreachable: Bool?
        /// Report restarted guests.
        public var restarted: Bool?
        /// CPU threshold.
        public var cpu: PVEThreshold?
        /// Memory threshold.
        public var mem: PVEThreshold?
        /// Disk threshold.
        public var disk: PVEThreshold?
        /// Report only after this many queries (1 to 60).
        public var delay: Int?
        /// Channel IDs for the notifications: `nil` inherits, an empty array uses the default channels.
        public var channels: [Int]?

        public init(
            crashed: Bool? = nil,
            stopped: Bool? = nil,
            paused: Bool? = nil,
            suspended: Bool? = nil,
            offline: Bool? = nil,
            unreachable: Bool? = nil,
            restarted: Bool? = nil,
            cpu: PVEThreshold? = nil,
            mem: PVEThreshold? = nil,
            disk: PVEThreshold? = nil,
            delay: Int? = nil,
            channels: [Int]? = nil
        ) {
            self.crashed = crashed
            self.stopped = stopped
            self.paused = paused
            self.suspended = suspended
            self.offline = offline
            self.unreachable = unreachable
            self.restarted = restarted
            self.cpu = cpu
            self.mem = mem
            self.disk = disk
            self.delay = delay
            self.channels = channels
        }
    }

    /// Schema `PVESettings`: settings of one level (system, node, guest or container).
    public struct PVESettings: Codable, Hashable, Sendable {
        /// ID of the system.
        public let systemID: Int?
        /// Level key; empty is the system itself.
        public let key: String?
        /// Muted.
        public let muted: Bool?
        /// Monitored as a healthcheck.
        public let asCheck: Bool?
        /// Token of the check.
        public let checkToken: String?
        /// Whether the guest is expected to run; `nil` is automatic.
        public let expectRunning: Bool?
        /// Seen running at least once.
        public let seenRunning: Bool?
        /// Rules of this level.
        public let rules: PVERuleSet?

        enum CodingKeys: String, CodingKey {
            case systemID = "system_id"
            case key, muted
            case asCheck = "as_check"
            case checkToken = "check_token"
            case expectRunning = "expect_running"
            case seenRunning = "seen_running"
            case rules
        }
    }

    /// Value of `expect_running` in ``PVESettingsInput``.
    public enum PVEExpectRunning: Hashable, Sendable {
        /// Automatic (sends `null`).
        case automatic
        /// The guest should run.
        case running
        /// The guest should not run.
        case stopped
    }

    /// Schema `PVESettingsInput`: partial update of one level.
    public struct PVESettingsInput: Encodable, Hashable, Sendable {
        /// Mute the level.
        public var muted: Bool?
        /// Create (`true`) or delete (`false`) the healthcheck of this level.
        public var asCheck: Bool?
        /// Expected state; `nil` leaves it, ``PVEExpectRunning/automatic`` sends `null`.
        public var expectRunning: PVEExpectRunning?
        /// Rules of this level.
        public var rules: PVERuleSet?

        public init(
            muted: Bool? = nil,
            asCheck: Bool? = nil,
            expectRunning: PVEExpectRunning? = nil,
            rules: PVERuleSet? = nil
        ) {
            self.muted = muted
            self.asCheck = asCheck
            self.expectRunning = expectRunning
            self.rules = rules
        }

        enum CodingKeys: String, CodingKey {
            case muted
            case asCheck = "as_check"
            case expectRunning = "expect_running"
            case rules
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(muted, forKey: .muted)
            try container.encodeIfPresent(asCheck, forKey: .asCheck)
            switch expectRunning {
            case .automatic: try container.encodeNil(forKey: .expectRunning)
            case .running: try container.encode(true, forKey: .expectRunning)
            case .stopped: try container.encode(false, forKey: .expectRunning)
            case nil: break
            }
            try container.encodeIfPresent(rules, forKey: .rules)
        }
    }

    /// Result of the `settings` read endpoints.
    public struct PVESettingsOverview: Codable, Hashable, Sendable {
        /// ID of the system.
        public let systemID: Int?
        /// Settings per level key.
        public let items: [String: PVESettings]?
        /// Effective rule per key (`""` is the system); `channels` holds the effective channel IDs.
        public let effective: JSONValue?
        /// Default rules.
        public let defaults: JSONValue?

        enum CodingKeys: String, CodingKey {
            case systemID = "system_id"
            case items, effective, defaults
        }
    }

    /// Result of the `updateSettings` endpoints.
    public struct PVESettingsResult: Codable, Hashable, Sendable {
        /// The stored settings of the level.
        public let settings: PVESettings?
        /// Effective rules after the change.
        public let effective: JSONValue?
    }
}
