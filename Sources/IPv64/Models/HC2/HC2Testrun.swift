import Foundation

/// A test run started when moving a check to another execution location.
public struct HC2Testrun: Codable, Hashable, Sendable, Identifiable {
    /// Test run number.
    public let id: Int
    /// Status of the test run.
    public let status: HC2TestrunStatus?
    /// Target execution location.
    public let target: String?
    /// The change has been applied.
    public let applied: Bool?
    /// Result per measuring point.
    public let results: [Result]?
    /// Error message.
    public let error: String?

    /// Result of one measuring point.
    public struct Result: Codable, Hashable, Sendable {
        /// Source of the measurement.
        public let source: String?
        /// The measurement succeeded.
        public let ok: Bool?
        /// Message.
        public let message: String?
    }
}
