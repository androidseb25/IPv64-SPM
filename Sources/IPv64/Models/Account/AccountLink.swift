import Foundation

/// An account link (sharing of account management).
public struct AccountLink: Codable, Hashable, Sendable, Identifiable {
    /// Link ID.
    public let id: Int
    /// Direction of the link.
    public let direction: AccountLinkDirection?
    /// Email of the other account.
    public let email: String?
    /// Status of the link.
    public let status: AccountLinkStatus?
    /// Creation time.
    public let createdAt: Date?
    /// Last use.
    public let lastUsedAt: Date?
    /// Only for managed accounts: the ID for `X-IPv64-Act-As`.
    public let accountID: Int?

    enum CodingKeys: String, CodingKey {
        case id, direction, email, status
        case createdAt = "created_at"
        case lastUsedAt = "last_used_at"
        case accountID = "account_id"
    }
}

/// Direction of an ``AccountLink``.
public struct AccountLinkDirection: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// You shared your account.
    public static let sharedWith: Self = "shared_with"
    /// You manage the other account.
    public static let managed: Self = "managed"
}

/// Status of an ``AccountLink``.
public struct AccountLinkStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let active: Self = "active"
    public static let pending: Self = "pending"
}
