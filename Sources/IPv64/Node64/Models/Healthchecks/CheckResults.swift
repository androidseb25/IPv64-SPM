import Foundation

extension Node64 {
    /// Result of ``Node64/HC/Checks/bulk(_:tokens:tag:)``.
    public struct CheckBulkResult: Codable, Hashable, Sendable {
        /// Number of checks the action succeeded for.
        public let done: Int?
        /// Checks the action failed for.
        public let failed: [CheckBulkFailure]?
    }

    /// A check a bulk action failed for.
    public struct CheckBulkFailure: Codable, Hashable, Sendable {
        /// Token of the check.
        public let token: String?
        /// Error message.
        public let error: String?
    }

    /// Result of ``Node64/HC/Checks/onlineTest(_:token:)``.
    public struct CheckOnlineTestResult: Codable, Hashable, Sendable {
        /// Overall outcome.
        public let status: CheckOnlineTestStatus?
        /// Error message.
        public let error: String?
        /// Result per ipv64 location.
        public let results: [CheckOnlineTestLocationResult]?
    }

    /// Result of one ipv64 location in a ``CheckOnlineTestResult``.
    public struct CheckOnlineTestLocationResult: Codable, Hashable, Sendable {
        /// Location code.
        public let location: String?
        /// The check succeeded there.
        public let ok: Bool?
        /// Message.
        public let message: String?
    }

    /// Answer of a push heartbeat (`{"status": "ok"}`).
    public struct PushResult: Codable, Hashable, Sendable {
        /// `ok` on success.
        public let status: String?
    }
}
