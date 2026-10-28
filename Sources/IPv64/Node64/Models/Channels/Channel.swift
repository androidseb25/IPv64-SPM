import Foundation

extension Node64 {
    /// Type of a notification channel (`browser`, `telegram`, `webhook`, …). Open enum.
    public struct ChannelType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let browser: Self = "browser"
        public static let smtp: Self = "smtp"
        public static let telegram: Self = "telegram"
        public static let discord: Self = "discord"
        public static let slack: Self = "slack"
        public static let teams: Self = "teams"
        public static let matrix: Self = "matrix"
        public static let secntfy: Self = "secntfy"
        public static let ntfy: Self = "ntfy"
        public static let gotify: Self = "gotify"
        public static let pushover: Self = "pushover"
        public static let homeAssistant: Self = "homeassistant"
        public static let webhook: Self = "webhook"
        public static let ipv64Mail: Self = "ipv64_mail"
        public static let ipv64SMS: Self = "ipv64_sms"
        public static let app: Self = "app"
    }

    /// Who sends the notifications of a channel. Open enum.
    public struct ChannelExecution: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// This node sends.
        public static let node: Self = "node"
        /// ipv64 sends (channel of the portal or another node); only name and switches are editable here.
        public static let server: Self = "server"
    }

    /// Notification channel. Schema `Channel`.
    public struct Channel: Codable, Hashable, Sendable, Identifiable {
        /// Channel ID.
        public let id: Int
        /// Channel type.
        public let type: ChannelType?
        /// Display name.
        public let name: String?
        /// Type specific fields (see ``Node64/HC/Channels/types()``). Secrets are masked unless
        /// requested with `includeSecrets`.
        public let config: [String: JSONValue]?
        /// Whether the channel is active.
        public let enabled: Bool?
        /// Whether the channel is used by default for new checks.
        public let isDefault: Bool?
        /// Language of the messages.
        public let lang: String?
        /// Notify when a check goes down.
        public let notifyDown: Bool?
        /// Notify when a check is up again.
        public let notifyUp: Bool?
        /// Who sends the messages (read-only).
        public let execution: ChannelExecution?
        /// Revision counter.
        public let revision: Int?
        /// Time of the last use (as sent by the node).
        public let lastUsedAt: String?
        /// Last delivery error.
        public let lastError: String?
        /// Creation time (read-only).
        public let createdAt: Date?
        /// Last change (read-only).
        public let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, type, name, config, enabled
            case isDefault = "default"
            case lang
            case notifyDown = "notify_down"
            case notifyUp = "notify_up"
            case execution, revision
            case lastUsedAt = "last_used_at"
            case lastError = "last_error"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// Writable fields of a notification channel (request body of create and update).
    ///
    /// When updating, empty secrets in `config` keep the stored value.
    public struct ChannelInput: Encodable, Hashable, Sendable {
        /// Channel type.
        public var type: ChannelType?
        /// Display name.
        public var name: String?
        /// Type specific fields, e.g. `["bot_token": .string("…"), "chat_id": .string("123")]`.
        public var config: [String: JSONValue]?
        /// Whether the channel is active.
        public var enabled: Bool?
        /// Whether the channel is used by default.
        public var isDefault: Bool?
        /// Language of the messages.
        public var lang: String?
        /// Notify when a check goes down.
        public var notifyDown: Bool?
        /// Notify when a check is up again.
        public var notifyUp: Bool?

        public init(
            type: ChannelType? = nil,
            name: String? = nil,
            config: [String: JSONValue]? = nil,
            enabled: Bool? = nil,
            isDefault: Bool? = nil,
            lang: String? = nil,
            notifyDown: Bool? = nil,
            notifyUp: Bool? = nil
        ) {
            self.type = type
            self.name = name
            self.config = config
            self.enabled = enabled
            self.isDefault = isDefault
            self.lang = lang
            self.notifyDown = notifyDown
            self.notifyUp = notifyUp
        }

        enum CodingKeys: String, CodingKey {
            case type, name, config, enabled
            case isDefault = "default"
            case lang
            case notifyDown = "notify_down"
            case notifyUp = "notify_up"
        }
    }

    /// Result of ``Node64/HC/Channels/sendTest(_:)``.
    public struct ChannelTestResult: Codable, Hashable, Sendable {
        /// `true` when the test message was delivered.
        public let ok: Bool?
        /// Error text (only on failure).
        public let error: String?
    }

    /// Entry of the delivery log. Schema `Delivery`.
    public struct Delivery: Codable, Hashable, Sendable, Identifiable {
        /// Log entry ID.
        public let id: Int
        /// Time of the delivery.
        public let time: Date?
        /// ID of the event that caused the message.
        public let eventID: String?
        /// ID of the channel.
        public let channelID: Int?
        /// Name of the channel.
        public let channel: String?
        /// Kind of the message.
        public let kind: String?
        /// Token of the check concerned.
        public let checkToken: String?
        /// Subject of the message.
        public let subject: String?
        /// Whether the delivery succeeded.
        public let ok: Bool?
        /// Error text; addresses are shortened to scheme and host.
        public let error: String?

        enum CodingKeys: String, CodingKey {
            case id, time
            case eventID = "event_id"
            case channelID = "channel_id"
            case channel, kind
            case checkToken = "check_token"
            case subject, ok, error
        }
    }
}
