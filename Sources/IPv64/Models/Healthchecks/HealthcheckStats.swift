import Foundation

/// Availability and latency of a healthcheck, calculated from stored events.
public struct HealthcheckStats: Codable, Hashable, Sendable {
    /// Requested range, e.g. `24h`.
    public let range: HealthcheckStatsRange?
    /// Start of the range.
    public let from: Date?
    /// End of the range.
    public let to: Date?
    /// Number of measurements.
    public let measurements: Int?
    /// Availability in percent.
    public let availabilityPercent: Double?
    /// Latency summary in milliseconds.
    public let latencyMs: Latency?
    /// Width of one series point in seconds.
    public let bucketSeconds: Int?
    /// Time series.
    public let series: [Point]?

    /// Latency summary in milliseconds.
    public struct Latency: Codable, Hashable, Sendable {
        /// Average.
        public let avg: Double?
        /// Minimum.
        public let min: Double?
        /// Maximum.
        public let max: Double?
    }

    /// One point of the time series.
    public struct Point: Codable, Hashable, Sendable {
        /// Start of the interval.
        public let time: Date?
        /// Measurements in the interval.
        public let measurements: Int?
        /// Availability in percent.
        public let availabilityPercent: Double?
        /// Average latency in milliseconds.
        public let latencyAvgMs: Double?
        /// Maximum latency in milliseconds.
        public let latencyMaxMs: Double?

        enum CodingKeys: String, CodingKey {
            case time, measurements
            case availabilityPercent = "availability_percent"
            case latencyAvgMs = "latency_avg_ms"
            case latencyMaxMs = "latency_max_ms"
        }
    }

    enum CodingKeys: String, CodingKey {
        case range, from, to, measurements
        case availabilityPercent = "availability_percent"
        case latencyMs = "latency_ms"
        case bucketSeconds = "bucket_seconds"
        case series
    }
}
