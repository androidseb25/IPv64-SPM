import Foundation

extension IPv64 {
    /// Threat intelligence from Honeypot64: IP lookups, statistics, early warning, password check and blocklist feed.
    public var threat: Threat { Threat(client: self) }

    /// Endpoints of the *Threat* area.
    public struct Threat: Sendable {
        let client: IPv64

        /// Why is this IP listed? Returns whether it is listed, its status (including releases), confidence
        /// score, lists, kinds, ports (only those reported by at least 2 accounts), first and last sighting,
        /// number of reporting accounts, and country/ASN if known. Unlisted IPs have no details.
        ///
        /// The API key is optional; an invalid key results in 401. Without a key the limit is 10 requests
        /// at once, then 1 per minute per client IP; with a key 120 at once, then 2 per second per account.
        ///
        /// - Parameter ip: Exactly one public IPv4 or IPv6 address (not a network).
        ///
        /// `GET /threat/ip/{ip}`
        public func ip(_ ip: String) async throws -> ThreatIP {
            try await client.send(Request(.get, "/threat/ip/\(ip)", authorization: .optional))
        }

        /// Public overview as on the Honeypot64 statistics page: active sensors, attacks in 24 hours, 30-day
        /// timeline, top ports and kinds, list sizes, top usernames, passwords, paths, user agents and origin
        /// countries. Rankings only contain entries reported by at least `threshold.accounts` accounts.
        /// Cached for at most 10 minutes (503 if currently unavailable).
        ///
        /// The API key is optional; limits as for ``ip(_:)``.
        ///
        /// `GET /threat/stats`
        public func stats() async throws -> ThreatStats {
            try await client.send(Request(.get, "/threat/stats", authorization: .optional))
        }

        /// Password check with k-anonymity, like the range API of Have I Been Pwned.
        ///
        /// Compute the SHA-1 of the password locally and send only the first 5 hex characters. The response is
        /// `text/plain` with one line `<remaining 35 hex characters, uppercase>:<count>` per password (CRLF,
        /// sorted) that attackers tried at Honeypot64 sensors in the last 365 days and at least 2 or 3
        /// independent accounts reported. The response has at least 64 lines; missing ones are padded with
        /// random lines with count 0. Cached for 1 hour. Limits as for ``ip(_:)``.
        ///
        /// - Parameter prefix: The first 5 hex characters of SHA-1(password), upper or lower case.
        /// - Returns: The raw response text. See ``passwordRangeEntries(prefix:)`` for a parsed variant.
        ///
        /// `GET /threat/passwords/range/{prefix}`
        public func passwordRange(prefix: String) async throws -> String {
            try await client.sendText(Request(.get, "/threat/passwords/range/\(prefix)", authorization: .optional))
        }

        /// Like ``passwordRange(prefix:)``, but parsed into entries. Padding lines (count 0) are included.
        ///
        /// `GET /threat/passwords/range/{prefix}`
        public func passwordRangeEntries(prefix: String) async throws -> [ThreatPasswordRangeEntry] {
            ThreatPasswordRangeEntry.parse(try await passwordRange(prefix: prefix))
        }

        /// Changes of the v64 Blocklist and its sub-lists since a cursor, oldest first, at most 10 000 per call.
        ///
        /// Load the live list completely once and call this without `since` (returns only the current cursor).
        /// Then call regularly with `since` set to the previous ``ThreatFeed/next``; while
        /// ``ThreatFeed/more`` is `true`, continue immediately. Changes are kept for 30 days; an older cursor
        /// fails with HTTP 410 (`cursor_expired`): reload the live list and start again without `since`.
        /// Not available for class Standard unless a sensor of the account reported in the last 7 days
        /// (403 `feed_not_available`). Limit: 120 per account at once, then 2 per second.
        ///
        /// Use ``feed(since:ifNoneMatch:)`` to poll with an ETag and skip unchanged responses.
        ///
        /// - Parameter since: Cursor from the previous response's `next`; omit to get the current cursor only.
        ///
        /// `GET /threat/feed`
        public func feed(since: String? = nil) async throws -> ThreatFeed {
            try await client.send(Request(.get, "/threat/feed", query: [QueryItem("since", since)]))
        }

        /// Conditional variant of ``feed(since:)``: sends `If-None-Match` and reports
        /// ``ThreatFeedResult/notModified`` when the server answers 304.
        ///
        /// - Parameters:
        ///   - since: Cursor from the previous response's `next`.
        ///   - etag: ETag of the previous response with the same `since`.
        ///
        /// `GET /threat/feed`
        public func feed(since: String?, ifNoneMatch etag: String) async throws -> ThreatFeedResult {
            let (data, response) = try await client.perform(Request(
                .get, "/threat/feed",
                query: [QueryItem("since", since)],
                headers: ["If-None-Match": etag]
            ))
            if response.statusCode == 304 {
                return .notModified
            }
            let feed = try client.decodeEnvelope(ThreatFeed.self, from: data)
            return .changed(feed, etag: response.value(forHTTPHeaderField: "ETag"))
        }

        /// Early warning for your own networks and DynDNS IPs.
        public var watch: Watch { Watch(client: client) }

        /// Endpoints of the early warning (*Frühwarnung*).
        public struct Watch: Sendable {
            let client: IPv64

            /// Early warning for your networks: limits of your class, registered networks and the
            /// automatically watched DynDNS IPs (current public A/AAAA records of your domains).
            ///
            /// `GET /threat/watch`
            public func list() async throws -> ThreatWatch {
                try await client.send(Request(.get, "/threat/watch"))
            }

            /// Registers a public network (CIDR) or a single IP. Host bits are removed
            /// (`203.0.113.7/24` becomes `203.0.113.0/24`). Unverified networks (`verified` false) only
            /// alert for IPs on the v64 Blocklist.
            ///
            /// Errors: 422 `invalid_cidr`, `prefix_too_large` (larger than `limits.min_prefix_v4/v6`),
            /// `not_public`; 409 `duplicate`; 403 `limit_reached` (`limits.max` reached).
            ///
            /// - Parameters:
            ///   - cidr: Network in CIDR form or a single IP (IPv4 up to /16, IPv6 up to /32).
            ///   - label: Optional label (at most 100 characters).
            ///
            /// `POST /threat/watch`
            public func add(cidr: String, label: String? = nil) async throws -> ThreatWatchNetwork {
                try await client.send(Request(.post, "/threat/watch", body: .json(AddBody(cidr: cidr, label: label))))
            }

            /// Removes an own network. Earlier alerts are kept (with their `network_id`).
            ///
            /// - Parameter id: ID of the network.
            ///
            /// `DELETE /threat/watch/{id}`
            public func delete(_ id: Int) async throws {
                try await client.sendWithoutContent(Request(.delete, "/threat/watch/\(id)"))
            }

            /// Early-warning alerts: an IP from an own network or a DynDNS IP of the account was flagged as an
            /// attacker in the evaluation (every 30 minutes). Oldest first, at most 100 per call. The same IP
            /// alerts at most once per 24 hours unless it is newly listed. Alerts are kept for 90 days.
            ///
            /// Pass the returned ``ThreatWatchAlerts/next`` unchanged as `since` of the next call and discard
            /// duplicate IDs. Without new alerts `next` is the value you passed; for an empty `since` it is
            /// the current time minus 5 minutes.
            ///
            /// - Parameter since: Cursor from the previous `next`, or an RFC 3339 timestamp (alerts created
            ///   after it); omit for all alerts.
            ///
            /// `GET /threat/watch/alerts`
            public func alerts(since: String? = nil) async throws -> ThreatWatchAlerts {
                try await client.send(Request(.get, "/threat/watch/alerts", query: [QueryItem("since", since)]))
            }

            private struct AddBody: Encodable, Sendable {
                let cidr: String
                let label: String?
            }
        }
    }
}
