import Foundation

extension IPv64 {
    /// DNS failover policies.
    public var failover: Failover { Failover(client: self) }

    /// Endpoints of the *DNS-Failover* area.
    public struct Failover: Sendable {
        let client: IPv64

        /// All failover policies.
        ///
        /// `GET /failover/policies`
        public func list() async throws -> [FailoverPolicy] {
            try await client.send(Request(.get, "/failover/policies"))
        }

        /// Creates a failover policy.
        ///
        /// `POST /failover/policies`
        public func create(_ input: FailoverPolicyInput = FailoverPolicyInput()) async throws -> FailoverPolicy {
            try await client.send(Request(.post, "/failover/policies", body: .json(input)))
        }

        /// A single policy.
        ///
        /// `GET /failover/policies/{id}`
        public func get(_ id: String) async throws -> FailoverPolicy {
            try await client.send(Request(.get, "/failover/policies/\(id)"))
        }

        /// Changes a policy. Only non-`nil` fields are changed.
        /// `linking` cannot be changed during an active failover.
        ///
        /// `PATCH /failover/policies/{id}`
        public func update(_ id: String, _ input: FailoverPolicyInput) async throws -> FailoverPolicy {
            try await client.send(Request(.patch, "/failover/policies/\(id)", body: .json(input)))
        }

        /// Deletes a policy. Not possible while the failover is active.
        ///
        /// `DELETE /failover/policies/{id}`
        public func delete(_ id: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/failover/policies/\(id)"))
        }

        /// Pauses a policy.
        ///
        /// `POST /failover/policies/{id}/pause`
        public func pause(_ id: String) async throws -> FailoverPolicy {
            try await client.send(Request(.post, "/failover/policies/\(id)/pause"))
        }

        /// Resumes a paused policy.
        ///
        /// `POST /failover/policies/{id}/resume`
        public func resume(_ id: String) async throws -> FailoverPolicy {
            try await client.send(Request(.post, "/failover/policies/\(id)/resume"))
        }

        /// Switches to the replacement manually. Only in status `active`.
        /// The background service applies the change within seconds (`202 Accepted`).
        ///
        /// `POST /failover/policies/{id}/failover`
        public func failOver(_ id: String) async throws -> FailoverPolicy {
            try await client.send(Request(.post, "/failover/policies/\(id)/failover"))
        }

        /// Switches back manually. Only in status `failed_over`.
        /// The background service applies the change within seconds (`202 Accepted`).
        ///
        /// `POST /failover/policies/{id}/fallback`
        public func fallBack(_ id: String) async throws -> FailoverPolicy {
            try await client.send(Request(.post, "/failover/policies/\(id)/fallback"))
        }

        /// Adds a monitor: a healthcheck that triggers the failover.
        ///
        /// - Parameters:
        ///   - id: Policy ID.
        ///   - healthcheck: Healthcheck token.
        ///   - negate: Evaluate inverted.
        ///
        /// `POST /failover/policies/{id}/monitors`
        public func addMonitor(policy id: String, healthcheck: String, negate: Bool? = nil) async throws -> FailoverPolicy {
            struct Body: Encodable, Sendable {
                let healthcheck: String
                let negate: Bool?
            }
            return try await client.send(Request(
                .post, "/failover/policies/\(id)/monitors",
                body: .json(Body(healthcheck: healthcheck, negate: negate))
            ))
        }

        /// Removes a monitor.
        ///
        /// `DELETE /failover/policies/{id}/monitors/{token}`
        public func removeMonitor(policy id: String, healthcheck token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/failover/policies/\(id)/monitors/\(token)"))
        }

        /// Adds a rule that protects an A or AAAA record.
        ///
        /// Specify exactly one target: `targetIP`, `targetRecord` or `offlinePage`.
        /// With `offlinePage` the record points to the IPv64 offline page during the failover.
        ///
        /// - Parameters:
        ///   - id: Policy ID.
        ///   - record: Record ID or token of the protected record.
        ///   - targetIP: Replacement IP of the same family.
        ///   - targetRecord: Another own record whose IP is taken over.
        ///   - offlinePage: `default` or an offline page ID.
        ///
        /// `POST /failover/policies/{id}/rules`
        public func addRule(
            policy id: String,
            record: String,
            targetIP: String? = nil,
            targetRecord: String? = nil,
            offlinePage: String? = nil
        ) async throws -> FailoverPolicy {
            struct Body: Encodable, Sendable {
                let record: String
                let targetIP: String?
                let targetRecord: String?
                let offlinePage: String?

                enum CodingKeys: String, CodingKey {
                    case record
                    case targetIP = "target_ip"
                    case targetRecord = "target_record"
                    case offlinePage = "offline_page"
                }
            }
            return try await client.send(Request(
                .post, "/failover/policies/\(id)/rules",
                body: .json(Body(record: record, targetIP: targetIP, targetRecord: targetRecord, offlinePage: offlinePage))
            ))
        }

        /// Removes a rule.
        ///
        /// - Parameters:
        ///   - id: Policy ID.
        ///   - record: Record ID or record token.
        ///
        /// `DELETE /failover/policies/{id}/rules/{record}`
        public func removeRule(policy id: String, record: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/failover/policies/\(id)/rules/\(record)"))
        }
    }
}
