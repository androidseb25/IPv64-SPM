import Foundation

extension IPv64.HC2 {
    /// Endpoints for healthchecks 2.0 checks.
    public struct Checks: Sendable {
        let client: IPv64

        /// Lists checks.
        ///
        /// - Parameters:
        ///   - type: Filter by check type.
        ///   - state: Filter by state (`up`, `down`, `degraded`, `flapping`, `paused`, `pending`).
        ///   - execution: Filter by execution location (`online`, `local`, `both`).
        ///   - nodeID: Filter by node.
        ///   - tag: Filter by tag.
        ///   - group: Filter by group.
        ///   - query: Search in name and target.
        ///
        /// `GET /hc2/checks`
        public func list(
            type: HC2CheckType? = nil,
            state: HC2CheckState? = nil,
            execution: HC2Execution? = nil,
            nodeID: String? = nil,
            tag: String? = nil,
            group: String? = nil,
            query: String? = nil
        ) async throws -> [HC2Check] {
            try await client.send(Request(.get, "/hc2/checks", query: [
                QueryItem("type", type),
                QueryItem("state", state),
                QueryItem("execution", execution),
                QueryItem("node_id", nodeID),
                QueryItem("tag", tag),
                QueryItem("group", group),
                QueryItem("q", query),
            ]))
        }

        /// Creates a check.
        ///
        /// Online checks count against the limit per location and must not have private targets;
        /// local checks need a linked node.
        ///
        /// `POST /hc2/checks`
        public func create(_ check: HC2CheckInput) async throws -> HC2CheckDetail {
            try await client.send(Request(.post, "/hc2/checks", body: .json(check)))
        }

        /// A check with its measuring points and availability.
        ///
        /// - Parameter token: Check token (32 characters).
        ///
        /// `GET /hc2/checks/{token}`
        public func get(_ token: String) async throws -> HC2CheckDetail {
            try await client.send(Request(.get, "/hc2/checks/\(token)"))
        }

        /// Updates a check. Only the fields provided are changed.
        ///
        /// Changing `execution`, `nodeID` or `locations` is not applied directly (`409 move_requires_test`);
        /// use ``move(_:execution:nodeID:nodes:locations:)`` with a test run instead.
        ///
        /// `PATCH /hc2/checks/{token}`
        public func update(_ token: String, _ check: HC2CheckInput) async throws -> HC2CheckDetail {
            try await client.send(Request(.patch, "/hc2/checks/\(token)", body: .json(check)))
        }

        /// Deletes a check.
        ///
        /// `DELETE /hc2/checks/{token}`
        public func delete(_ token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/hc2/checks/\(token)"))
        }

        /// Pauses a check.
        ///
        /// `POST /hc2/checks/{token}/pause`
        public func pause(_ token: String) async throws -> HC2Check {
            try await client.send(Request(.post, "/hc2/checks/\(token)/pause"))
        }

        /// Resumes a paused check.
        ///
        /// `POST /hc2/checks/{token}/resume`
        public func resume(_ token: String) async throws -> HC2Check {
            try await client.send(Request(.post, "/hc2/checks/\(token)/resume"))
        }

        /// Runs a check immediately. For node checks this queues a command for the node.
        ///
        /// `POST /hc2/checks/{token}/run`
        public func run(_ token: String) async throws -> HC2CheckRunResult {
            try await client.send(Request(.post, "/hc2/checks/\(token)/run"))
        }

        /// Moves a check to another execution location with a test run.
        ///
        /// The hub measures per location, the node via command. Poll ``testrun(_:)`` every 2 seconds
        /// (at most 60 seconds). On status `ok` the change is applied; token and measurement history are kept.
        ///
        /// - Parameters:
        ///   - token: Check token.
        ///   - execution: Target execution location.
        ///   - nodeID: Owner node for `local`/`both`; given alone it means a single measuring node.
        ///   - nodes: Measuring node IDs for `local`/`both` (Docker/Push exactly one).
        ///   - locations: Locations for `online`/`both`.
        ///
        /// `POST /hc2/checks/{token}/move`
        public func move(
            _ token: String,
            execution: HC2Execution,
            nodeID: String? = nil,
            nodes: [String]? = nil,
            locations: [HC2Location]? = nil
        ) async throws -> HC2Testrun {
            struct Body: Encodable, Sendable {
                let execution: HC2Execution
                let nodeID: String?
                let nodes: [String]?
                let locations: [HC2Location]?

                enum CodingKeys: String, CodingKey {
                    case execution
                    case nodeID = "node_id"
                    case nodes, locations
                }
            }
            let body = Body(execution: execution, nodeID: nodeID, nodes: nodes, locations: locations)
            return try await client.send(Request(.post, "/hc2/checks/\(token)/move", body: .json(body)))
        }

        /// Status of a test run.
        ///
        /// `GET /hc2/testruns/{id}`
        public func testrun(_ id: Int) async throws -> HC2Testrun {
            try await client.send(Request(.get, "/hc2/testruns/\(id)"))
        }

        /// Raw measurements of a check, newest first (last 7 days).
        ///
        /// - Parameters:
        ///   - token: Check token.
        ///   - limit: At most 5000.
        ///   - since: Only measurements from this point in time.
        ///   - until: Only measurements until this point in time.
        ///   - source: Source filter: `loc:nbg`, `loc:fsn`, `node:<id>`.
        ///
        /// `GET /hc2/checks/{token}/measurements`
        public func measurements(
            _ token: String,
            limit: Int? = nil,
            since: Date? = nil,
            until: Date? = nil,
            source: String? = nil
        ) async throws -> [HC2Measurement] {
            try await client.send(Request(.get, "/hc2/checks/\(token)/measurements", query: [
                QueryItem("limit", limit),
                QueryItem("since", since),
                QueryItem("until", until),
                QueryItem("source", source),
            ]))
        }

        /// Events of a check, newest first.
        ///
        /// - Parameters:
        ///   - token: Check token.
        ///   - limit: Page size, at most 100.
        ///   - before: Only events with a smaller ID (older). Use `meta.nextBefore` of the previous page.
        ///   - after: Only events with a larger ID (newer, ascending order).
        ///   - since: Only events from this point in time.
        ///
        /// `GET /hc2/checks/{token}/events`
        public func events(
            _ token: String,
            limit: Int? = nil,
            before: Int? = nil,
            after: Int? = nil,
            since: Date? = nil
        ) async throws -> IPv64Page<HC2Event, HC2PageMeta> {
            try await client.sendPage(Request(.get, "/hc2/checks/\(token)/events", query: [
                QueryItem("limit", limit),
                QueryItem("before", before),
                QueryItem("after", after),
                QueryItem("since", since),
            ]))
        }

        /// Availability and latency of a check (from hourly/daily values).
        ///
        /// - Parameters:
        ///   - token: Check token.
        ///   - range: `24h`, `7d`, `30d` or `1y`.
        ///
        /// `GET /hc2/checks/{token}/stats`
        public func stats(_ token: String, range: HC2StatsRange? = nil) async throws -> HC2Stats {
            try await client.send(Request(.get, "/hc2/checks/\(token)/stats", query: [QueryItem("range", range)]))
        }
    }
}

/// Result of ``IPv64/HC2/Checks/run(_:)``.
public struct HC2CheckRunResult: Codable, Hashable, Sendable {
    /// The run was queued.
    public let queued: Bool?
    /// Command number (node checks, `202`).
    public let commandID: Int?
    /// Node the command was sent to (node checks, `202`).
    public let nodeID: String?
    /// Details.
    public let detail: String?

    enum CodingKeys: String, CodingKey {
        case queued
        case commandID = "command_id"
        case nodeID = "node_id"
        case detail
    }
}
