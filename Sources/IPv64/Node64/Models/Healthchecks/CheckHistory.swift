import Foundation

extension Node64 {
    /// A single measurement of a check. Schema `Measurement`.
    public struct CheckMeasurement: Codable, Hashable, Sendable, Identifiable {
        /// Sequence number; use it as `before` cursor.
        public let seq: Int
        /// Time of the measurement.
        public let time: String?
        /// Result.
        public let status: CheckMeasurementStatus?
        /// Latency in milliseconds.
        public let latencyMS: Double?
        /// Reason code.
        public let reason: String?
        /// Message.
        public let message: String?
        /// IP family that was measured.
        public let family: String?
        /// Type-dependent details.
        public let details: [String: JSONValue]?
        /// A maintenance window was active.
        public let maintenance: Bool?
        /// The result depends on a parent check.
        public let dependent: Bool?

        public var id: Int { seq }

        enum CodingKeys: String, CodingKey {
            case seq, time, status
            case latencyMS = "latency_ms"
            case reason, message, family, details, maintenance, dependent
        }
    }

    /// A state change of a check. Schema `Event`.
    public struct CheckEvent: Codable, Hashable, Sendable, Identifiable {
        /// Event ID; use it as `before` cursor.
        public let id: Int
        /// Global event ID.
        public let eventID: String?
        /// Token of the check.
        public let token: String?
        /// Kind of event.
        public let kind: String?
        /// Time of the event.
        public let time: String?
        /// Previous state.
        public let from: String?
        /// New state.
        public let to: String?
        /// Reason code.
        public let reason: String?
        /// Message.
        public let message: String?
        /// Duration of the previous state in seconds.
        public let durationSeconds: Int?
        /// Number of flaps.
        public let flaps: Int?
        /// A maintenance window was active.
        public let maintenance: Bool?
        /// No notification was sent.
        public let silent: Bool?
        /// ID of the related incident.
        public let incidentID: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case eventID = "event_id"
            case token, kind, time, from, to, reason, message
            case durationSeconds = "duration_seconds"
            case flaps, maintenance, silent
            case incidentID = "incident_id"
        }
    }

    /// An outage of a check. Schema `Incident`.
    public struct CheckIncident: Codable, Hashable, Sendable, Identifiable {
        /// Incident ID.
        public let id: Int
        /// Token of the check.
        public let token: String?
        /// Start of the outage.
        public let startedAt: String?
        /// End of the outage.
        public let endedAt: String?
        /// The outage is ongoing.
        public let open: Bool?
        /// Reason code.
        public let reason: String?
        /// Message.
        public let message: String?

        enum CodingKeys: String, CodingKey {
            case id, token
            case startedAt = "started_at"
            case endedAt = "ended_at"
            case open, reason, message
        }
    }

    /// Availability and latency of a check as time series. Schema `Stats`.
    public struct CheckStats: Codable, Hashable, Sendable {
        /// Requested range.
        public let range: String?
        /// Start of the range.
        public let from: String?
        /// End of the range.
        public let to: String?
        /// Number of measurements.
        public let count: Int?
        /// Number of successful measurements.
        public let upCount: Int?
        /// Availability in percent.
        public let upPercent: Double?
        /// Average latency in milliseconds.
        public let avgMS: Double?
        /// Minimum latency in milliseconds.
        public let minMS: Double?
        /// Maximum latency in milliseconds.
        public let maxMS: Double?
        /// Width of a series bucket in seconds.
        public let bucketSeconds: Int?
        /// Time series.
        public let series: [CheckStatsPoint]?

        enum CodingKeys: String, CodingKey {
            case range, from, to, count
            case upCount = "up_count"
            case upPercent = "up_percent"
            case avgMS = "avg_ms"
            case minMS = "min_ms"
            case maxMS = "max_ms"
            case bucketSeconds = "bucket_seconds"
            case series
        }
    }

    /// One bucket of ``CheckStats/series``.
    public struct CheckStatsPoint: Codable, Hashable, Sendable {
        /// Start of the bucket.
        public let time: String?
        /// Number of measurements.
        public let count: Int?
        /// Number of successful measurements.
        public let upCount: Int?
        /// Average latency in milliseconds.
        public let avgMS: Double?
        /// Minimum latency in milliseconds.
        public let minMS: Double?
        /// Maximum latency in milliseconds.
        public let maxMS: Double?
        /// Availability in percent.
        public let upPercent: Double?

        enum CodingKeys: String, CodingKey {
            case time, count
            case upCount = "up_count"
            case avgMS = "avg_ms"
            case minMS = "min_ms"
            case maxMS = "max_ms"
            case upPercent = "up_percent"
        }
    }

    /// Latency per measuring point, result of ``Node64/HC/Checks/chart(_:range:)``.
    public struct CheckChart: Codable, Hashable, Sendable {
        /// Requested range.
        public let range: String?
        /// Aggregation of the points.
        public let bucket: CheckChartBucket?
        /// One series per measuring point.
        public let series: [CheckChartSeries]?
    }

    /// Series of one measuring point in a ``CheckChart``.
    public struct CheckChartSeries: Codable, Hashable, Sendable {
        /// `self`, `node:<id>` or `loc:<code>`.
        public let source: String?
        /// Display name.
        public let label: String?
        /// Data points.
        public let points: [CheckChartPoint]?
    }

    /// Data point of a ``CheckChartSeries``.
    public struct CheckChartPoint: Codable, Hashable, Sendable {
        /// Time.
        public let t: Date?
        /// Latency in milliseconds; `nil` means down or no measurement.
        public let ms: Double?
        /// Availability in percent (hourly and daily buckets only).
        public let up: Double?
    }
}
