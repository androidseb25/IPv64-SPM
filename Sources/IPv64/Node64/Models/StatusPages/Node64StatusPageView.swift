import Foundation

extension Node64 {
    /// What a status page shows right now (`GET /status-pages/{id}/view`), same structure as the page's `status.json`.
    ///
    /// The spec only says "free object", so the raw JSON is kept in ``raw``. Typically it holds the overall state, `sections`
    /// (`section` empty = Healthchecks, `systems` = Monitor64) with groups and the state of each entry, maintenances and incidents.
    public struct StatusPageView: Codable, Hashable, Sendable {
        /// The complete JSON object.
        public let raw: JSONValue

        /// Reads a top-level field of ``raw``.
        public subscript(key: String) -> JSONValue? { raw[key] }

        public init(raw: JSONValue) { self.raw = raw }

        public init(from decoder: any Decoder) throws {
            raw = try decoder.singleValueContainer().decode(JSONValue.self)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(raw)
        }
    }
}
