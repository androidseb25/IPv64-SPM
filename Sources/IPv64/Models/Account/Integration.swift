import Foundation

/// A notification integration.
public struct Integration: Codable, Hashable, Sendable, Identifiable {
    /// Integration ID; 0 is the account email.
    public let id: Int
    /// Kind of integration.
    public let type: IntegrationType?
    /// Name.
    public let name: String?
    /// Status; email and SMS must be confirmed first.
    public let status: IntegrationStatus?
    /// Preselected for new healthchecks.
    public let isDefault: Bool?
    /// Settings per type. Secrets are shortened unless `includeSecrets` was requested.
    public let options: [String: JSONValue]?
    /// Creation time.
    public let createdAt: Date?
    /// Last use.
    public let lastUsedAt: Date?
    /// Number of messages sent.
    public let uses: Int?

    enum CodingKeys: String, CodingKey {
        case id, type, name, status
        case isDefault = "default"
        case options
        case createdAt = "created_at"
        case lastUsedAt = "last_used_at"
        case uses
    }
}

/// Kind of an ``Integration``.
public struct IntegrationType: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// The email address of the account.
    public static let accountEmail: Self = "account_email"
    public static let telegram: Self = "telegram"
    public static let gotify: Self = "gotify"
    public static let ntfy: Self = "ntfy"
    public static let pushover: Self = "pushover"
    public static let discord: Self = "discord"
    public static let webhook: Self = "webhook"
    public static let email: Self = "email"
    public static let sms: Self = "sms"
    /// The IPv64 app.
    public static let app: Self = "app"
}

/// Status of an ``Integration``.
public struct IntegrationStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let active: Self = "active"
    /// Email or SMS confirmation is outstanding.
    public static let pendingVerification: Self = "pending_verification"
}

/// Input for ``IPv64/Integrations/create(_:)``. Which fields are needed depends on `type`.
///
/// - telegram: `chatID`, `apiToken`
/// - gotify: `serverURL`, `appToken`, `priority` (0 to 10)
/// - ntfy: `serverURL` (including topic), `priorityDown` and `priorityUp` (1 to 5)
/// - pushover: `userToken`, `appToken`, `device`, `priority` (-2 to 1)
/// - discord: `webhookURL`, `pingUser`, `pingGroup`
/// - webhook: `urlDown` and/or `urlUp`
/// - email: `email` (a confirmation link is sent)
/// - sms: `number` (German mobile number), `countryCode` `0049` (a confirmation link is sent by SMS)
/// - app: `deviceToken` of the IPv64 app
///
/// URLs must start with http or https and point to public addresses.
public struct IntegrationInput: Encodable, Hashable, Sendable {
    /// Kind of integration.
    public var type: IntegrationType
    /// Name.
    public var name: String
    /// Preselect for new healthchecks.
    public var isDefault: Bool?
    /// telegram: chat ID.
    public var chatID: String?
    /// telegram: bot token.
    public var apiToken: String?
    /// gotify, ntfy: server URL.
    public var serverURL: String?
    /// gotify, pushover: app token.
    public var appToken: String?
    /// pushover: user token.
    public var userToken: String?
    /// pushover: device.
    public var device: String?
    /// gotify (0 to 10), pushover (-2 to 1): priority.
    public var priority: Int?
    /// ntfy: priority for down (1 to 5).
    public var priorityDown: Int?
    /// ntfy: priority for up (1 to 5).
    public var priorityUp: Int?
    /// discord: webhook URL.
    public var webhookURL: String?
    /// discord: user ID to ping.
    public var pingUser: String?
    /// discord: role ID to ping.
    public var pingGroup: String?
    /// webhook: URL called on DOWN.
    public var urlDown: String?
    /// webhook: URL called on UP.
    public var urlUp: String?
    /// email: address.
    public var email: String?
    /// sms: number.
    public var number: String?
    /// sms: country code, e.g. `0049`.
    public var countryCode: String?
    /// app: device token.
    public var deviceToken: String?

    public init(
        type: IntegrationType,
        name: String,
        isDefault: Bool? = nil,
        chatID: String? = nil,
        apiToken: String? = nil,
        serverURL: String? = nil,
        appToken: String? = nil,
        userToken: String? = nil,
        device: String? = nil,
        priority: Int? = nil,
        priorityDown: Int? = nil,
        priorityUp: Int? = nil,
        webhookURL: String? = nil,
        pingUser: String? = nil,
        pingGroup: String? = nil,
        urlDown: String? = nil,
        urlUp: String? = nil,
        email: String? = nil,
        number: String? = nil,
        countryCode: String? = nil,
        deviceToken: String? = nil
    ) {
        self.type = type
        self.name = name
        self.isDefault = isDefault
        self.chatID = chatID
        self.apiToken = apiToken
        self.serverURL = serverURL
        self.appToken = appToken
        self.userToken = userToken
        self.device = device
        self.priority = priority
        self.priorityDown = priorityDown
        self.priorityUp = priorityUp
        self.webhookURL = webhookURL
        self.pingUser = pingUser
        self.pingGroup = pingGroup
        self.urlDown = urlDown
        self.urlUp = urlUp
        self.email = email
        self.number = number
        self.countryCode = countryCode
        self.deviceToken = deviceToken
    }

    enum CodingKeys: String, CodingKey {
        case type, name
        case isDefault = "default"
        case chatID = "chat_id"
        case apiToken = "api_token"
        case serverURL = "server_url"
        case appToken = "app_token"
        case userToken = "user_token"
        case device, priority
        case priorityDown = "priority_down"
        case priorityUp = "priority_up"
        case webhookURL = "webhook_url"
        case pingUser = "ping_user"
        case pingGroup = "ping_group"
        case urlDown = "url_down"
        case urlUp = "url_up"
        case email, number
        case countryCode = "country_code"
        case deviceToken = "device_token"
    }
}

/// Result of ``IPv64/Integrations/sendTest(_:)``.
public struct IntegrationTestResult: Codable, Hashable, Sendable {
    /// The test message was sent.
    public let sent: Bool?
}
