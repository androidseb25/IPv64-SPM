import Foundation

/// A change of the v64 Blocklist.
public struct ThreatFeedChange: Codable, Hashable, Sendable {
    /// The IP address.
    public let ip: String?
    /// Kind of change.
    public let action: Action?
    /// Lists after the change (`v64`, `ssh`, `web`, `mail`, `rdp`, `scanner`, `research`); empty for `remove`.
    public let lists: [String]?
    /// Lists before the change; empty for `add`.
    public let previousLists: [String]?
    /// Time of the evaluation (UTC).
    public let at: Date?

    enum CodingKeys: String, CodingKey {
        case ip, action, lists
        case previousLists = "previous_lists"
        case at
    }

    /// Kind of change.
    public struct Action: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Newly listed.
        public static let add: Self = "add"
        /// No longer listed.
        public static let remove: Self = "remove"
        /// Different sub-lists.
        public static let update: Self = "update"
    }
}

/// A page of the v64 Blocklist change feed.
public struct ThreatFeed: Codable, Hashable, Sendable {
    /// Changes, oldest first (at most 10 000).
    public let changes: [ThreatFeedChange]?
    /// Opaque cursor; pass it unchanged as `since` of the next call.
    public let next: String?
    /// More changes are ready: fetch again immediately with `next`.
    public let more: Bool?
}

/// One line of a password range response: the remaining 35 hex characters of a SHA-1 and its count.
public struct ThreatPasswordRangeEntry: Hashable, Sendable {
    /// The remaining 35 hex characters of the SHA-1 hash (uppercase).
    public let suffix: String
    /// Number of times attackers tried the password. `0` marks a padding line.
    public let count: Int

    /// Parses a `text/plain` range response (`<35 hex>:<count>` per line, CRLF separated). Malformed lines are skipped.
    public static func parse(_ text: String) -> [ThreatPasswordRangeEntry] {
        text.split(whereSeparator: \.isNewline).compactMap { line in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, let count = Int(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
            return ThreatPasswordRangeEntry(suffix: String(parts[0]).uppercased(), count: count)
        }
    }
}

/// Result of the conditional ``IPv64/Threat/feed(since:ifNoneMatch:)``.
public enum ThreatFeedResult: Hashable, Sendable {
    /// New data, with the ETag to send on the next call with the same cursor.
    case changed(ThreatFeed, etag: String?)
    /// HTTP 304: nothing changed since the given ETag.
    case notModified
}
