import Foundation

extension Node64 {
    /// Severity of a status page notice.
    public struct StatusNoticeLevel: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Information.
        public static let info: Self = "info"
        /// Warning.
        public static let warning: Self = "warning"
        /// Danger (outage).
        public static let danger: Self = "danger"
        /// Empty string: leave the level unchanged (only for updates).
        public static let unchanged: Self = ""
    }

    /// Schema `StatusNotice`: an announcement on a status page with its timeline.
    public struct StatusNotice: Codable, Hashable, Sendable, Identifiable {
        /// ID of the notice.
        public let id: Int
        /// ID of the status page.
        public let pageID: Int?
        /// Title.
        public let title: String?
        /// Severity.
        public let level: StatusNoticeLevel?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last change.
        public let updatedAt: Date?
        /// Time it was marked resolved; absent while open.
        public let resolvedAt: Date?
        /// Timeline entries.
        public let updates: [StatusNoticeUpdate]?

        enum CodingKeys: String, CodingKey {
            case id
            case pageID = "page_id"
            case title, level
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case resolvedAt = "resolved_at"
            case updates
        }
    }

    /// An entry in the timeline of a ``StatusNotice``.
    public struct StatusNoticeUpdate: Codable, Hashable, Sendable, Identifiable {
        /// ID of the entry.
        public let id: Int
        /// Time of the entry.
        public let time: Date?
        /// Text in simple Markdown.
        public let text: String?
    }

    /// Schema `StatusNoticeInput`: body for creating a notice.
    public struct StatusNoticeInput: Encodable, Hashable, Sendable {
        /// Title (up to 200 characters).
        public var title: String
        /// Severity; the server defaults to `info`.
        public var level: StatusNoticeLevel?
        /// First timeline entry in simple Markdown (up to 5000 characters).
        public var text: String?

        public init(title: String, level: StatusNoticeLevel? = nil, text: String? = nil) {
            self.title = title
            self.level = level
            self.text = text
        }
    }

    /// Schema `StatusNoticeUpdateInput`: body for adding an update to a notice.
    public struct StatusNoticeUpdateInput: Encodable, Hashable, Sendable {
        /// New severity; `nil` or ``StatusNoticeLevel/unchanged`` keeps it.
        public var level: StatusNoticeLevel?
        /// Update text (up to 5000 characters); empty or `nil` adds none.
        public var text: String?
        /// Mark the notice as resolved.
        public var resolve: Bool?

        public init(level: StatusNoticeLevel? = nil, text: String? = nil, resolve: Bool? = nil) {
            self.level = level
            self.text = text
            self.resolve = resolve
        }
    }
}
