import Foundation

/// An entry of the account log.
public struct LogEntry: Codable, Hashable, Sendable, Identifiable {
    /// Log ID, also the cursor for `before`.
    public let id: Int
    /// Affected domain.
    public let domainID: Int?
    /// Category, e.g. `API Key`.
    public let title: String?
    /// Message text.
    public let message: String?
    /// Time of the entry.
    public let time: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case domainID = "domain_id"
        case title, message, time
    }
}
