import Foundation

extension IPv64 {
    /// Your account, its usage and limits, the account log and account links.
    public var account: Account { Account(client: self) }

    /// Endpoints of the *Account* area.
    public struct Account: Sendable {
        let client: IPv64

        /// Shows the plan, usage and limits as well as the credentials used for this request.
        ///
        /// `GET /me`
        public func me() async throws -> Me {
            try await client.send(Request(.get, "/me"))
        }

        /// The account log, newest entries first.
        ///
        /// Pass ``AccountLogMeta/nextBefore`` of the previous page as `before` to continue.
        /// Only entries within the retention period of the plan are returned.
        ///
        /// `GET /me/logs`
        /// - Parameters:
        ///   - limit: Number of entries (1 to 500, server default 50).
        ///   - before: Only entries with a smaller ID (cursor).
        ///   - since: Only entries from this point in time.
        public func logs(
            limit: Int? = nil,
            before: Int? = nil,
            since: Date? = nil
        ) async throws -> IPv64Page<LogEntry, AccountLogMeta> {
            try await client.sendPage(Request(.get, "/me/logs", query: [
                QueryItem("limit", limit),
                QueryItem("before", before),
                QueryItem("since", since),
            ]))
        }

        /// Account links: who may manage your account (`sharedWith`) and which accounts you may manage (`managed`).
        ///
        /// Use ``IPv64/actingAs(_:)`` to act for a managed account.
        ///
        /// `GET /me/account-links`
        public func links() async throws -> AccountLinks {
            try await client.send(Request(.get, "/me/account-links"))
        }
    }
}

/// Pagination metadata of ``IPv64/Account/logs(limit:before:since:)``.
public struct AccountLogMeta: Codable, Hashable, Sendable {
    /// Limit used for this page.
    public let limit: Int?
    /// Cursor for the next page (pass as `before`); `nil` at the end.
    public let nextBefore: Int?
    /// Retention of log entries in days.
    public let retentionDays: Int?

    enum CodingKeys: String, CodingKey {
        case limit
        case nextBefore = "next_before"
        case retentionDays = "retention_days"
    }
}

/// Result of ``IPv64/Account/links()``.
public struct AccountLinks: Codable, Hashable, Sendable {
    /// Accounts that may manage your account.
    public let sharedWith: [AccountLink]?
    /// Accounts you may manage.
    public let managed: [AccountLink]?

    enum CodingKeys: String, CodingKey {
        case sharedWith = "shared_with"
        case managed
    }
}
