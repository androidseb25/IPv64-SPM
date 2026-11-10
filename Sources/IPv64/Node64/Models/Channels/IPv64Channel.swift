import Foundation

extension Node64 {
    /// Channel at ipv64 (e-mail, SMS, app). Schema of `/ipv64/channels`.
    public struct IPv64Channel: Codable, Hashable, Sendable, Identifiable {
        /// Channel ID at ipv64.
        public let id: Int
        /// Channel type (`ipv64_mail`, `ipv64_sms`, `app`).
        public let type: ChannelType?
        /// Display name.
        public let name: String?
        /// Whether the channel is active.
        public let enabled: Bool?
        /// Whether the channel is used by default.
        public let isDefault: Bool?
        /// Confirmed by code.
        public let verified: Bool?
        /// Language of the messages.
        public let lang: String?
        /// Notify when a check goes down.
        public let notifyDown: Bool?
        /// Notify when a check is up again.
        public let notifyUp: Bool?
        /// Non-secret values (e-mail address or number).
        public let config: [String: JSONValue]?
        /// Last delivery error.
        public let lastError: String?

        enum CodingKeys: String, CodingKey {
            case id, type, name, enabled
            case isDefault = "default"
            case verified, lang
            case notifyDown = "notify_down"
            case notifyUp = "notify_up"
            case config
            case lastError = "last_error"
        }
    }

    /// Request body of `POST`/`PUT /ipv64/channels`.
    public struct IPv64ChannelInput: Encodable, Hashable, Sendable {
        /// `ipv64_mail` or `ipv64_sms`; required on create, only used there.
        public var type: ChannelType?
        /// Name (1 to 100 characters); required on create.
        public var name: String?
        /// Language of the messages.
        public var lang: String?
        /// Type fields: `["email": …]` or `["number": "+49 …"]`; unknown fields fail with 422.
        public var config: [String: JSONValue]?
        /// Whether the channel is active.
        public var enabled: Bool?
        /// Whether the channel is used by default.
        public var isDefault: Bool?
        /// Notify when a check goes down.
        public var notifyDown: Bool?
        /// Notify when a check is up again.
        public var notifyUp: Bool?

        public init(
            type: ChannelType? = nil,
            name: String? = nil,
            lang: String? = nil,
            config: [String: JSONValue]? = nil,
            enabled: Bool? = nil,
            isDefault: Bool? = nil,
            notifyDown: Bool? = nil,
            notifyUp: Bool? = nil
        ) {
            self.type = type
            self.name = name
            self.lang = lang
            self.config = config
            self.enabled = enabled
            self.isDefault = isDefault
            self.notifyDown = notifyDown
            self.notifyUp = notifyUp
        }

        enum CodingKeys: String, CodingKey {
            case type, name, lang, config, enabled
            case isDefault = "default"
            case notifyDown = "notify_down"
            case notifyUp = "notify_up"
        }
    }
}
