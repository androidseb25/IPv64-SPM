import Foundation

/// Language of a Healthchecks 2.0 status page.
public struct HC2StatusPageLanguage: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let auto: Self = "auto"
    public static let de: Self = "de"
    public static let en: Self = "en"
}

/// Color theme of a Healthchecks 2.0 status page.
public struct HC2StatusPageTheme: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let auto: Self = "auto"
    public static let light: Self = "light"
    public static let dark: Self = "dark"
}

/// Layout of a Healthchecks 2.0 status page.
public struct HC2StatusPageLayout: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// List with 90 days (default).
    public static let list: Self = "list"
    /// Small cards with the last 6 hours.
    public static let cards: Self = "cards"
}

/// Kind of a status page notice.
public struct HC2StatusNoticeKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let info: Self = "info"
    public static let maintenance: Self = "maintenance"
    public static let incident: Self = "incident"
}

/// A group of checks on a Healthchecks 2.0 status page. Used in responses and in ``HC2StatusPageInput/groups``.
public struct HC2StatusGroup: Codable, Hashable, Sendable {
    /// Heading of the group; empty means no heading.
    public var name: String?
    /// Tokens of the checks in display order.
    public var tokens: [String]

    /// Creates a group.
    public init(name: String? = nil, tokens: [String]) {
        self.name = name
        self.tokens = tokens
    }
}

/// A Healthchecks 2.0 status page.
public struct HC2StatusPage: Codable, Hashable, Sendable, Identifiable {
    /// Status page ID.
    public let id: Int
    /// Address (unique across all accounts).
    public let slug: String?
    /// Public page, `https://ipv64.net/healthchecks2/status/<slug>`.
    public let url: String?
    /// The same data as JSON (public).
    public let jsonURL: String?
    /// Title.
    public let title: String?
    /// Description.
    public let description: String?
    /// Language.
    public let lang: HC2StatusPageLanguage?
    /// Color theme.
    public let theme: HC2StatusPageTheme?
    /// Layout.
    public let layout: HC2StatusPageLayout?
    /// `false` means visible only through ``previewURL``.
    public let published: Bool?
    /// Show incidents of the last 14 days.
    public let showHistory: Bool?
    /// Reload the page every minute.
    public let autorefresh: Bool?
    /// Address with preview key (also for hidden pages); do not share.
    public let previewURL: String?
    /// Groups of checks; only present when a single page is fetched.
    public let groups: [HC2StatusGroup]?
    /// Creation time.
    public let createdAt: Date?
    /// Last change.
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, slug, url
        case jsonURL = "json_url"
        case title, description, lang, theme, layout, published
        case showHistory = "show_history"
        case autorefresh
        case previewURL = "preview_url"
        case groups
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Request body for creating or updating a Healthchecks 2.0 status page. Only non-`nil` fields are sent.
///
/// When updating, missing fields stay unchanged; `groups` replaces all groups.
public struct HC2StatusPageInput: Encodable, Hashable, Sendable {
    /// Title, at most 120 characters; required when creating.
    public var title: String?
    /// Address (`^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$`), unique across all accounts; random when omitted on create.
    public var slug: String?
    /// Description, at most 1000 characters.
    public var description: String?
    /// Groups (at most 20, at most 100 checks per page, each check once).
    public var groups: [HC2StatusGroup]?
    /// Language.
    public var lang: HC2StatusPageLanguage?
    /// Color theme.
    public var theme: HC2StatusPageTheme?
    /// Layout.
    public var layout: HC2StatusPageLayout?
    /// Publish the page.
    public var published: Bool?
    /// Show incidents of the last 14 days.
    public var showHistory: Bool?
    /// Reload the page every minute.
    public var autorefresh: Bool?

    /// Creates a status page body.
    public init(
        title: String? = nil,
        slug: String? = nil,
        description: String? = nil,
        groups: [HC2StatusGroup]? = nil,
        lang: HC2StatusPageLanguage? = nil,
        theme: HC2StatusPageTheme? = nil,
        layout: HC2StatusPageLayout? = nil,
        published: Bool? = nil,
        showHistory: Bool? = nil,
        autorefresh: Bool? = nil
    ) {
        self.title = title
        self.slug = slug
        self.description = description
        self.groups = groups
        self.lang = lang
        self.theme = theme
        self.layout = layout
        self.published = published
        self.showHistory = showHistory
        self.autorefresh = autorefresh
    }

    enum CodingKeys: String, CodingKey {
        case title, slug, description, groups, lang, theme, layout, published
        case showHistory = "show_history"
        case autorefresh
    }
}

/// A notice (info, maintenance or incident) on a status page.
public struct HC2StatusNotice: Codable, Hashable, Sendable, Identifiable {
    /// Notice ID.
    public let id: Int
    /// Kind.
    public let kind: HC2StatusNoticeKind?
    /// Title.
    public let title: String?
    /// Text.
    public let body: String?
    /// Resolved; stays on the page for another 7 days.
    public let resolved: Bool?
    /// Creation time.
    public let createdAt: Date?
    /// Time it was resolved, `nil` while open.
    public let resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, kind, title, body, resolved
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }
}

/// Request body for creating or updating a status page notice. Only non-`nil` fields are sent.
public struct HC2StatusNoticeInput: Encodable, Hashable, Sendable {
    /// Kind.
    public var kind: HC2StatusNoticeKind?
    /// Title, at most 200 characters; required when creating.
    public var title: String?
    /// Text, at most 2000 characters.
    public var body: String?
    /// Resolved; stays on the page for another 7 days.
    public var resolved: Bool?

    /// Creates a notice body.
    public init(
        kind: HC2StatusNoticeKind? = nil,
        title: String? = nil,
        body: String? = nil,
        resolved: Bool? = nil
    ) {
        self.kind = kind
        self.title = title
        self.body = body
        self.resolved = resolved
    }
}
