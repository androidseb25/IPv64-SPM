import Foundation

/// An API key. The key itself is never shown again, only its start and end.
public struct APIKey: Codable, Hashable, Sendable, Identifiable {
    /// Key ID.
    public let id: Int
    /// Name.
    public let name: String?
    /// Start and end of the key, e.g. `1ZK4…Rx5e`.
    public let tokenHint: String?
    /// Creation time.
    public let createdAt: Date?
    /// Expiry; `nil` means never.
    public let expiresAt: Date?
    /// The key has expired.
    public let expired: Bool?
    /// Number of calls made with the key.
    public let uses: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case tokenHint = "token_hint"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case expired, uses
    }
}

/// A freshly created API key, including the full key.
public struct APIKeyCreated: Codable, Hashable, Sendable, Identifiable {
    /// Key ID.
    public let id: Int
    /// Name.
    public let name: String?
    /// Start and end of the key.
    public let tokenHint: String?
    /// Creation time.
    public let createdAt: Date?
    /// Expiry; `nil` means never.
    public let expiresAt: Date?
    /// The key has expired.
    public let expired: Bool?
    /// Number of calls made with the key.
    public let uses: Int?
    /// The full key. Shown only this one time.
    public let token: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case tokenHint = "token_hint"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case expired, uses, token
    }
}
