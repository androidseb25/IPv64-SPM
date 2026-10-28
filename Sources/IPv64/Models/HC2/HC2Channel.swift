import Foundation

/// A notification channel.
public struct HC2Channel: Codable, Hashable, Sendable, Identifiable {
    /// Channel ID.
    public let id: Int
    /// Channel type.
    public let type: HC2ChannelKind?
    /// Human-readable channel type.
    public let typeLabel: String?
    /// Name.
    public let name: String?
    /// Configuration without secrets.
    public let config: [String: JSONValue]?
    /// Names of the secret fields that are set.
    public let secretsSet: [String]?
    /// Enabled.
    public let enabled: Bool?
    /// Default channel.
    public let `default`: Bool?
    /// Mail/SMS: confirmed by code.
    public let verified: Bool?
    /// Language: `de` or `en`.
    public let lang: HC2ChannelLanguage?
    /// Notify on failure.
    public let notifyDown: Bool?
    /// Notify on recovery.
    public let notifyUp: Bool?
    /// Where the channel sends from: `server` or `node`.
    public let execution: HC2ChannelExecution?
    /// Node ID for node channels.
    public let nodeID: String?
    /// Last use.
    public let lastUsed: Date?
    /// Last error.
    public let lastError: String?
    /// Revision.
    public let revision: Int?
    /// Creation time.
    public let createdAt: Date?
    /// Usable via `POST /hc2/channels/{id}/send` (verified, active ipv64 channel).
    public let sendableViaAPI: Bool?

    enum CodingKeys: String, CodingKey {
        case id, type
        case typeLabel = "type_label"
        case name, config
        case secretsSet = "secrets_set"
        case enabled
        case `default`
        case verified, lang
        case notifyDown = "notify_down"
        case notifyUp = "notify_up"
        case execution
        case nodeID = "node_id"
        case lastUsed = "last_used"
        case lastError = "last_error"
        case revision
        case createdAt = "created_at"
        case sendableViaAPI = "sendable_via_api"
    }
}

/// Request body for creating or updating a channel.
public struct HC2ChannelInput: Encodable, Hashable, Sendable {
    /// Channel type (only when creating).
    public var type: HC2ChannelKind?
    /// Name.
    public var name: String
    /// Fields according to ``IPv64/HC2/Channels/types()``; omit secret fields when updating to keep them unchanged.
    public var config: [String: JSONValue]?
    /// Enabled.
    public var enabled: Bool?
    /// Default channel.
    public var `default`: Bool?
    /// Language: `de` or `en`.
    public var lang: HC2ChannelLanguage?
    /// Notify on failure.
    public var notifyDown: Bool?
    /// Notify on recovery.
    public var notifyUp: Bool?

    /// Creates a channel body.
    public init(
        name: String,
        type: HC2ChannelKind? = nil,
        config: [String: JSONValue]? = nil,
        enabled: Bool? = nil,
        default: Bool? = nil,
        lang: HC2ChannelLanguage? = nil,
        notifyDown: Bool? = nil,
        notifyUp: Bool? = nil
    ) {
        self.name = name
        self.type = type
        self.config = config
        self.enabled = enabled
        self.default = `default`
        self.lang = lang
        self.notifyDown = notifyDown
        self.notifyUp = notifyUp
    }

    enum CodingKeys: String, CodingKey {
        case type, name, config, enabled
        case `default`
        case lang
        case notifyDown = "notify_down"
        case notifyUp = "notify_up"
    }
}

/// A channel type with its configuration fields.
public struct HC2ChannelType: Codable, Hashable, Sendable {
    /// Type identifier.
    public let type: HC2ChannelKind?
    /// Human-readable name.
    public let label: String?
    /// Needs verification by code (mail/SMS).
    public let needsVerification: Bool?
    /// Configuration fields.
    public let fields: [Field]?

    /// A configuration field of a channel type.
    public struct Field: Codable, Hashable, Sendable {
        /// Key in `config`.
        public let key: String?
        /// Label.
        public let label: String?
        /// Input kind.
        public let kind: HC2ChannelFieldKind?
        /// Required.
        public let required: Bool?
        /// Secret value (write-only).
        public let secret: Bool?
        /// Options for `select` fields.
        public let options: [String]?
        /// Default value.
        public let `default`: String?

        enum CodingKeys: String, CodingKey {
            case key, label, kind, required, secret, options
            case `default`
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, label
        case needsVerification = "needs_verification"
        case fields
    }
}
