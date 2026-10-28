import Foundation

/// An offline page that is shown while a failover is active.
public struct OfflinePage: Codable, Hashable, Sendable, Identifiable {
    /// Offline page ID (16 characters).
    public let id: String
    /// Heading.
    public let name: String?
    /// Domain the page appears under.
    public let domain: String?
    /// Contact e-mail.
    public let email: String?
    /// Phone number.
    public let phone: String?
    /// Alternative address.
    public let alternativeURL: String?
    /// Text as HTML.
    public let text: String?
    /// Logo URL.
    public let iconURL: String?
    /// Number of views.
    public let views: Int?
    /// ID of the failover policy using this page.
    public let inUseByPolicy: String?
    /// The page is currently being served.
    public let active: Bool?
    /// Preview URL.
    public let previewURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, domain, email, phone
        case alternativeURL = "alternative_url"
        case text
        case iconURL = "icon_url"
        case views
        case inUseByPolicy = "in_use_by_policy"
        case active
        case previewURL = "preview_url"
    }
}

/// Request body to create or update an offline page. Only non-`nil` fields are sent.
public struct OfflinePageInput: Encodable, Hashable, Sendable {
    /// Heading.
    public var name: String?
    /// Domain the page applies to.
    public var domain: String?
    /// Contact e-mail.
    public var email: String?
    /// Phone number, digits and an optional leading `+`.
    public var phone: String?
    /// Alternative address.
    public var alternativeURL: String?
    /// Text. Line breaks are kept, HTML is escaped.
    public var text: String?

    public init(
        name: String? = nil,
        domain: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        alternativeURL: String? = nil,
        text: String? = nil
    ) {
        self.name = name
        self.domain = domain
        self.email = email
        self.phone = phone
        self.alternativeURL = alternativeURL
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case name, domain, email, phone
        case alternativeURL = "alternative_url"
        case text
    }
}
