import Foundation

/// The personal list token for the live version of the v64 Blocklist. Treat the token as a secret.
public struct HoneypotListToken: Codable, Hashable, Sendable {
    /// The token (32 alphanumeric characters).
    public let token: String
    /// The account may use the live list right now; otherwise the URL serves the daily list.
    public let live: Bool
    /// Base URL; append a list file name such as `ipv64_blocklist_v64.txt`.
    public let base: String

    enum CodingKeys: String, CodingKey {
        case token, live, base
    }
}
