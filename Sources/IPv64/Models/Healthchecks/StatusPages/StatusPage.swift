import Foundation

/// A public status page.
public struct StatusPage: Codable, Hashable, Sendable, Identifiable {
    /// ID.
    public let id: Int
    /// Title.
    public let name: String?
    /// Address behind `/status/`.
    public let slug: String?
    /// Public URL.
    public let url: String?
    /// Description.
    public let description: String?
    /// Protected by a password.
    public let passwordProtected: Bool?
    /// Design, 1 to 4.
    public let design: Int?
    /// The page reloads automatically.
    public let autorefresh: Bool?
    /// Tokens of the displayed healthchecks, in display order.
    public let healthchecks: [String]?
    /// Creation time.
    public let createdAt: Date?
    /// Last view.
    public let lastViewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, url, description
        case passwordProtected = "password_protected"
        case design, autorefresh, healthchecks
        case createdAt = "created_at"
        case lastViewedAt = "last_viewed_at"
    }
}

/// Request body to create or update a status page. Only non-`nil` fields are sent.
public struct StatusPageInput: Encodable, Hashable, Sendable {
    /// Title.
    public var name: String?
    /// Description.
    public var description: String?
    /// Address, 3 to 128 characters a-z, A-Z, 0-9. Random if omitted on creation.
    public var slug: String?
    /// Password. An empty string makes the page public.
    public var password: String?
    /// Design, 1 to 4.
    public var design: Int?
    /// Reload the page automatically.
    public var autorefresh: Bool?
    /// Tokens of the healthchecks to display.
    public var healthchecks: [String]?

    public init(
        name: String? = nil,
        description: String? = nil,
        slug: String? = nil,
        password: String? = nil,
        design: Int? = nil,
        autorefresh: Bool? = nil,
        healthchecks: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.slug = slug
        self.password = password
        self.design = design
        self.autorefresh = autorefresh
        self.healthchecks = healthchecks
    }
}
