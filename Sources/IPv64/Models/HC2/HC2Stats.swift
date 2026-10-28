import Foundation

/// Availability and latency of a check.
public struct HC2Stats: Codable, Hashable, Sendable {
    /// Range, e.g. `24h`.
    public let range: HC2StatsRange?
    /// Aggregation bucket: `hour` or `day`.
    public let bucket: HC2StatsBucket?
    /// Number of measurements.
    public let measurements: Int?
    /// Overall availability in percent.
    public let availabilityPercent: Double?
    /// Statistics per measuring point.
    public let sources: [Source]?
    /// Time series.
    public let series: [Point]?

    /// Statistics of one measuring point.
    public struct Source: Codable, Hashable, Sendable {
        /// Source: `loc:nbg`, `loc:fsn` or `node:<id>`.
        public let source: String?
        /// Human-readable name.
        public let label: String?
        /// Number of measurements.
        public let measurements: Int?
        /// Availability in percent.
        public let availabilityPercent: Double?
        /// Latency in milliseconds.
        public let latencyMS: Latency?

        enum CodingKeys: String, CodingKey {
            case source, label, measurements
            case availabilityPercent = "availability_percent"
            case latencyMS = "latency_ms"
        }
    }

    /// Latency figures in milliseconds.
    public struct Latency: Codable, Hashable, Sendable {
        /// Minimum.
        public let min: Double?
        /// Average.
        public let avg: Double?
        /// Maximum.
        public let max: Double?
    }

    /// A point of the time series.
    public struct Point: Codable, Hashable, Sendable {
        /// Start of the bucket.
        public let time: Date?
        /// Source of the point.
        public let source: String?
        /// Number of measurements.
        public let measurements: Int?
        /// Availability in percent.
        public let availabilityPercent: Double?
        /// Average latency in milliseconds.
        public let latencyAvgMS: Double?
        /// Maximum latency in milliseconds.
        public let latencyMaxMS: Double?

        enum CodingKeys: String, CodingKey {
            case time, source, measurements
            case availabilityPercent = "availability_percent"
            case latencyAvgMS = "latency_avg_ms"
            case latencyMaxMS = "latency_max_ms"
        }
    }

    enum CodingKeys: String, CodingKey {
        case range, bucket, measurements
        case availabilityPercent = "availability_percent"
        case sources, series
    }
}
