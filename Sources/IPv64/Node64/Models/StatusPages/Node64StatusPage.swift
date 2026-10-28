import Foundation

extension Node64 {
    /// Layout of a status page.
    public struct StatusPageLayout: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Entries as a list.
        public static let list: Self = "list"
        /// Entries as tiles.
        public static let tiles: Self = "tiles"
        /// Compact entries.
        public static let compact: Self = "compact"
    }

    /// Color theme of a status page.
    public struct StatusPageTheme: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Follow the browser setting.
        public static let auto: Self = "auto"
        /// Light theme.
        public static let light: Self = "light"
        /// Dark theme.
        public static let dark: Self = "dark"
    }

    /// Language of a status page.
    public struct StatusPageLanguage: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Language of the visitor's browser (empty string).
        public static let browser: Self = ""
        /// German.
        public static let de: Self = "de"
        /// English.
        public static let en: Self = "en"
    }

    /// Schema `StatusPage`: a public status page with groups of checks.
    ///
    /// The password is never returned, only ``hasPassword``.
    public struct StatusPage: Codable, Hashable, Sendable, Identifiable {
        /// ID of the page.
        public let id: Int
        /// Slug in the URL `/status/<slug>`.
        public let slug: String?
        /// Title (up to 120 characters).
        public let title: String
        /// Description in simple Markdown.
        public let description: String?
        /// Footer in simple Markdown.
        public let footer: String?
        /// `false` makes the page unreachable everywhere, also through PROXY64.
        public let enabled: Bool?
        /// Serve the page directly on the node port under `/status/<slug>`.
        public let publishNode: Bool?
        /// Layout of the entries.
        public let layout: StatusPageLayout?
        /// Color theme.
        public let theme: StatusPageTheme?
        /// Language (empty = language of the browser).
        public let lang: StatusPageLanguage?
        /// Accent color as `#rrggbb`, empty for the default.
        public let accent: String?
        /// Number of day bars (30, 60 or 90).
        public let days: Int?
        /// Show uptime percentages.
        public let showUptime: Bool?
        /// Show incidents and notices of the last 30 days.
        public let showHistory: Bool?
        /// Refresh interval of the page in seconds (30 to 3600).
        public let refreshSec: Int?
        /// A password protects the page.
        public let hasPassword: Bool?
        /// Ask search engines not to index the page.
        public let noindex: Bool?
        /// Show "provided with Node64".
        public let poweredBy: Bool?
        /// Groups with their entries (at most 50 groups and 1000 entries).
        public let groups: [StatusGroup]?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last change.
        public let updatedAt: Date?
        /// Show entries in the healthcheck groups; the page's groups then only select and order.
        public let hcGroups: Bool?
        /// A custom logo is uploaded.
        public let hasLogo: Bool?
        /// Time of the last logo change (absent without logo).
        public let logoUpdated: Date?

        enum CodingKeys: String, CodingKey {
            case id, slug, title, description, footer, enabled
            case publishNode = "publish_node"
            case layout, theme, lang, accent, days
            case showUptime = "show_uptime"
            case showHistory = "show_history"
            case refreshSec = "refresh_sec"
            case hasPassword = "has_password"
            case noindex
            case poweredBy = "powered_by"
            case groups
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case hcGroups = "hc_groups"
            case hasLogo = "has_logo"
            case logoUpdated = "logo_updated"
        }
    }

    /// Schema `StatusGroup`: a group of entries on a status page.
    public struct StatusGroup: Codable, Hashable, Sendable, Identifiable {
        /// ID of the group (changes whenever the groups of the page are replaced).
        public let id: Int
        /// Heading (up to 100 characters), empty for no heading.
        public let name: String?
        /// Entries of the group.
        public let items: [StatusItem]?
    }

    /// Schema `StatusItem`: an entry (check) of a group.
    public struct StatusItem: Codable, Hashable, Sendable, Identifiable {
        /// ID of the entry.
        public let id: Int
        /// Token of the check.
        public let token: String
        /// Display name (up to 120 characters); empty uses the check's name.
        public let label: String?
    }

    /// A group to send when creating or replacing the groups of a status page.
    public struct StatusPageGroupInput: Encodable, Hashable, Sendable {
        /// Heading (up to 100 characters), empty for none.
        public var name: String?
        /// Entries of the group.
        public var items: [StatusPageItemInput]?

        public init(name: String? = nil, items: [StatusPageItemInput]? = nil) {
            self.name = name
            self.items = items
        }
    }

    /// An entry to send inside a ``StatusPageGroupInput``.
    public struct StatusPageItemInput: Encodable, Hashable, Sendable {
        /// Token of the check.
        public var token: String
        /// Display name (up to 120 characters); empty uses the check's name.
        public var label: String?

        public init(token: String, label: String? = nil) {
            self.token = token
            self.label = label
        }
    }

    /// Writable fields of a status page for create (`POST`) and partial update (`PUT`).
    ///
    /// Only non-`nil` fields are sent. On create, missing fields get defaults
    /// (layout `list`, theme `auto`, 90 days, refresh 60 s; `publish_node`, `show_uptime`,
    /// `show_history`, `noindex` and `powered_by` on; `enabled` and `hc_groups` off).
    public struct StatusPageInput: Encodable, Hashable, Sendable {
        /// Slug; empty on create derives it from the title.
        public var slug: String?
        /// Title (required on create, up to 120 characters).
        public var title: String?
        /// Description in simple Markdown (up to 5000 characters).
        public var description: String?
        /// Footer in simple Markdown (up to 2000 characters).
        public var footer: String?
        /// Whether the page is reachable.
        public var enabled: Bool?
        /// Serve the page directly on the node port.
        public var publishNode: Bool?
        /// Layout.
        public var layout: StatusPageLayout?
        /// Color theme.
        public var theme: StatusPageTheme?
        /// Language.
        public var lang: StatusPageLanguage?
        /// Accent color `#rrggbb`.
        public var accent: String?
        /// Day bars: 30, 60 or 90.
        public var days: Int?
        /// Show uptime percentages.
        public var showUptime: Bool?
        /// Show incidents and notices of the last 30 days.
        public var showHistory: Bool?
        /// Refresh interval in seconds (30 to 3600).
        public var refreshSec: Int?
        /// New password (4 to 72 characters); `"-"` removes it; `nil` or empty keeps it.
        public var password: String?
        /// Ask search engines not to index the page.
        public var noindex: Bool?
        /// Show "provided with Node64".
        public var poweredBy: Bool?
        /// Replaces all groups and entries (their IDs change); `nil` keeps them.
        public var groups: [StatusPageGroupInput]?
        /// Show entries in the healthcheck groups.
        public var hcGroups: Bool?

        public init(
            slug: String? = nil,
            title: String? = nil,
            description: String? = nil,
            footer: String? = nil,
            enabled: Bool? = nil,
            publishNode: Bool? = nil,
            layout: StatusPageLayout? = nil,
            theme: StatusPageTheme? = nil,
            lang: StatusPageLanguage? = nil,
            accent: String? = nil,
            days: Int? = nil,
            showUptime: Bool? = nil,
            showHistory: Bool? = nil,
            refreshSec: Int? = nil,
            password: String? = nil,
            noindex: Bool? = nil,
            poweredBy: Bool? = nil,
            groups: [StatusPageGroupInput]? = nil,
            hcGroups: Bool? = nil
        ) {
            self.slug = slug
            self.title = title
            self.description = description
            self.footer = footer
            self.enabled = enabled
            self.publishNode = publishNode
            self.layout = layout
            self.theme = theme
            self.lang = lang
            self.accent = accent
            self.days = days
            self.showUptime = showUptime
            self.showHistory = showHistory
            self.refreshSec = refreshSec
            self.password = password
            self.noindex = noindex
            self.poweredBy = poweredBy
            self.groups = groups
            self.hcGroups = hcGroups
        }

        enum CodingKeys: String, CodingKey {
            case slug, title, description, footer, enabled
            case publishNode = "publish_node"
            case layout, theme, lang, accent, days
            case showUptime = "show_uptime"
            case showHistory = "show_history"
            case refreshSec = "refresh_sec"
            case password, noindex
            case poweredBy = "powered_by"
            case groups
            case hcGroups = "hc_groups"
        }
    }
}
