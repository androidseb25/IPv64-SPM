import Foundation

extension IPv64 {
    /// Honeypot64: report attacks from your own sensors and see your contribution.
    public var honeypot: Honeypot { Honeypot(client: self) }

    /// Endpoints of the *Honeypot64* area.
    public struct Honeypot: Sendable {
        let client: IPv64

        /// Accepts a report from a sensor.
        ///
        /// Only for Node64 (module `honeypot` or `NODE64_MODE=honeypot`). The uncompressed body may be at most
        /// 2 MiB, with at most 5000 sources and 500 samples per kind (otherwise 413). A known `reportID` returns
        /// the existing report with ``HoneypotReportAccepted/duplicate`` set (counts as success). At most one
        /// report per sensor every 2 minutes (429 with `Retry-After`); new sensors per account are limited to 5
        /// (class Standard) or 25 (other classes), counting sensors that reported in the last 30 days
        /// (otherwise 403 `sensor_limit`). Sources with private or reserved IPs, the IP of an own sensor, or an
        /// unknown kind or service are dropped and counted in ``HoneypotReportAccepted/rejected``.
        ///
        /// `POST /honeypot/reports`
        public func submitReport(_ report: HoneypotReport) async throws -> HoneypotReportAccepted {
            try await client.send(Request(.post, "/honeypot/reports", body: .json(report)))
        }

        /// Sensors of the account with their contribution over 24 hours and 7 days. A sensor's IP is never returned.
        ///
        /// `GET /honeypot/sensors`
        public func sensors() async throws -> [HoneypotSensor] {
            try await client.send(Request(.get, "/honeypot/sensors"))
        }

        /// The personal list token for the live version of the v64 Blocklist.
        ///
        /// Creates the token if it is missing and keeps an existing one. The full list URL is ``HoneypotListToken/base``
        /// plus a list file name, e.g. `ipv64_blocklist_v64.txt`. If ``HoneypotListToken/live`` is `false`
        /// (plan class Standard and not a contributor), that URL serves the daily list (header `X-IPv64-List: daily`).
        /// The token is a secret: do not log it.
        ///
        /// `GET /honeypot/list-token`
        public func listToken() async throws -> HoneypotListToken {
            try await client.send(Request(.get, "/honeypot/list-token"))
        }

        /// The account's own contribution: events and distinct source IPs over 24 hours and 7 days, top kinds
        /// and ports (7 days) and a per-day timeline (UTC, 7 days).
        ///
        /// `GET /honeypot/stats`
        public func stats() async throws -> HoneypotStats {
            try await client.send(Request(.get, "/honeypot/stats"))
        }
    }
}
