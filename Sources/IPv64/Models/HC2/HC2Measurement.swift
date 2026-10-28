import Foundation

/// A raw measurement point of a check.
public struct HC2Measurement: Codable, Hashable, Sendable {
    /// Time of the measurement.
    public let time: Date?
    /// Source: `loc:nbg`, `loc:fsn` or `node:<id>`.
    public let source: String?
    /// Human-readable name of the source.
    public let sourceLabel: String?
    /// Result: `up` or `down`.
    public let status: HC2MeasurementStatus?
    /// Latency in milliseconds.
    public let latencyMS: Double?
    /// Reason of the result.
    public let reason: String?
    /// Message of the result.
    public let message: String?
    /// IP family used: `ipv4` or `ipv6`.
    public let family: String?
    /// Raw details.
    public let details: JSONValue?

    enum CodingKeys: String, CodingKey {
        case time, source
        case sourceLabel = "source_label"
        case status
        case latencyMS = "latency_ms"
        case reason, message, family, details
    }
}
