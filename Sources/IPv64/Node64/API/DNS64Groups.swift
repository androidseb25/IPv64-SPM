import Foundation

extension Node64.DNS64 {
    /// Device groups: members, rules, domains, instant button and schedules.
    public var groups: Groups { Groups(client: client) }

    /// Endpoints of `/dns64/groups`.
    public struct Groups: Sendable {
        let client: Node64

        /// Members (devices and networks) of groups.
        public var members: Members { Members(client: client) }
        /// Allow and block entries of groups.
        public var domains: Domains { Domains(client: client) }
        /// Time schedules of groups.
        public var schedules: Schedules { Schedules(client: client) }

        /// Lists the device groups with their members, rules and current state, in order of precedence.
        ///
        /// `GET /dns64/groups`
        public func list() async throws -> [Node64.DNS64Group] {
            try await client.send(Request(.get, "/dns64/groups"))
        }

        /// Creates a group.
        ///
        /// `POST /dns64/groups`
        public func create(name: String) async throws -> Node64.DNS64Group {
            try await client.send(Request(.post, "/dns64/groups", body: .json(NameBody(name: name))))
        }

        /// Renames a group.
        ///
        /// `PUT /dns64/groups/{id}`
        public func rename(_ id: Int, to name: String) async throws {
            try await client.sendWithoutContent(Request(.put, "/dns64/groups/\(id)", body: .json(NameBody(name: name))))
        }

        /// Deletes a group together with its members.
        ///
        /// `DELETE /dns64/groups/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/dns64/groups/\(id)"))
        }

        /// Moves a group in the order of precedence.
        ///
        /// - Parameter up: `true` moves the group up (higher precedence), `false` down.
        ///
        /// `POST /dns64/groups/{id}/move`
        public func move(_ id: Int, up: Bool) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/groups/\(id)/move", body: .json(MoveBody(up: up))))
        }

        /// Changes the rules of a group: block lists (global/custom), categories, safe search,
        /// YouTube restriction and filter bypass.
        ///
        /// Fields left `nil` are not sent. The spec does not state whether the node keeps or resets
        /// omitted fields, so pass every rule you want the group to have (start from ``list()``).
        ///
        /// `PUT /dns64/groups/{id}/rules`
        public func updateRules(
            _ id: Int,
            listsMode: Node64.DNS64GroupListsMode? = nil,
            lists: [String]? = nil,
            categories: [Node64.DNS64GroupCategory]? = nil,
            safesearch: Bool? = nil,
            youtube: Node64.DNS64GroupYouTubeMode? = nil,
            bypass: Bool? = nil
        ) async throws {
            let body = RulesBody(
                listsMode: listsMode, lists: lists, categories: categories,
                safesearch: safesearch, youtube: youtube, bypass: bypass
            )
            try await client.sendWithoutContent(Request(.put, "/dns64/groups/\(id)/rules", body: .json(body)))
        }

        /// Instant button: turns the internet off (`block`), suspends schedules and categories
        /// (`free`) or releases an active hold (empty mode).
        ///
        /// - Parameters:
        ///   - mode: `.block`, `.free` or `.none` to release.
        ///   - minutes: Duration; `0` means until released.
        ///   - untilMorning: Hold until 07:00 the next morning (node time zone).
        ///
        /// `POST /dns64/groups/{id}/hold`
        public func hold(
            _ id: Int,
            mode: Node64.DNS64GroupHoldMode,
            minutes: Int? = nil,
            untilMorning: Bool? = nil
        ) async throws {
            let body = HoldBody(mode: mode, minutes: minutes, untilMorning: untilMorning)
            try await client.sendWithoutContent(Request(.post, "/dns64/groups/\(id)/hold", body: .json(body)))
        }

        private struct NameBody: Encodable, Sendable {
            let name: String
        }

        private struct MoveBody: Encodable, Sendable {
            let up: Bool
        }

        private struct RulesBody: Encodable, Sendable {
            let listsMode: Node64.DNS64GroupListsMode?
            let lists: [String]?
            let categories: [Node64.DNS64GroupCategory]?
            let safesearch: Bool?
            let youtube: Node64.DNS64GroupYouTubeMode?
            let bypass: Bool?

            enum CodingKeys: String, CodingKey {
                case listsMode = "lists_mode"
                case lists, categories, safesearch, youtube, bypass
            }
        }

        private struct HoldBody: Encodable, Sendable {
            let mode: Node64.DNS64GroupHoldMode
            let minutes: Int?
            let untilMorning: Bool?

            enum CodingKeys: String, CodingKey {
                case mode, minutes
                case untilMorning = "until_morning"
            }
        }

        /// Endpoints for group members.
        public struct Members: Sendable {
            let client: Node64

            /// Assigns a device or network to a group; it leaves any other group it was in.
            ///
            /// - Parameters:
            ///   - group: ID of the group.
            ///   - kind: Kind of `value`.
            ///   - value: MAC address, IP address or network (CIDR).
            ///   - label: Display name.
            /// - Returns: The new membership; delete it with ``delete(_:)``.
            ///
            /// `POST /dns64/groups/{id}/members`
            public func create(
                group: Int,
                kind: Node64.DNS64GroupMemberKind,
                value: String,
                label: String? = nil
            ) async throws -> Node64.DNS64GroupMember {
                let body = Body(kind: kind, value: value, label: label)
                return try await client.send(Request(.post, "/dns64/groups/\(group)/members", body: .json(body)))
            }

            /// Removes a member from its group.
            ///
            /// - Parameter id: ID of the membership (``Node64/DNS64GroupMember/id``).
            ///
            /// `DELETE /dns64/groups/members/{id}`
            public func delete(_ id: Int) async throws {
                try await client.sendWithoutContent(Request(.delete, "/dns64/groups/members/\(id)"))
            }

            private struct Body: Encodable, Sendable {
                let kind: Node64.DNS64GroupMemberKind
                let value: String
                let label: String?
            }
        }

        /// Endpoints for group allow and block entries.
        public struct Domains: Sendable {
            let client: Node64

            /// Allows or blocks a domain (including subdomains) for a group.
            ///
            /// - Parameters:
            ///   - group: ID of the group.
            ///   - domain: Domain; applies to its subdomains too.
            ///   - action: Allow or block.
            /// - Returns: The new entry; delete it with ``delete(_:)``.
            ///
            /// `POST /dns64/groups/{id}/domains`
            public func create(
                group: Int,
                domain: String,
                action: Node64.DNS64GroupDomainAction
            ) async throws -> Node64.DNS64GroupDomain {
                let body = Body(domain: domain, action: action)
                return try await client.send(Request(.post, "/dns64/groups/\(group)/domains", body: .json(body)))
            }

            /// Deletes an allow or block entry of a group.
            ///
            /// `DELETE /dns64/groups/domains/{id}`
            public func delete(_ id: Int) async throws {
                try await client.sendWithoutContent(Request(.delete, "/dns64/groups/domains/\(id)"))
            }

            private struct Body: Encodable, Sendable {
                let domain: String
                let action: Node64.DNS64GroupDomainAction
            }
        }

        /// Endpoints for group schedules.
        public struct Schedules: Sendable {
            let client: Node64

            /// Creates a schedule for a group.
            ///
            /// - Parameters:
            ///   - group: ID of the group.
            ///   - input: The schedule.
            ///
            /// `POST /dns64/groups/{id}/schedules`
            public func create(
                group: Int,
                _ input: Node64.DNS64ScheduleInput
            ) async throws -> Node64.DNS64Schedule {
                try await client.send(Request(.post, "/dns64/groups/\(group)/schedules", body: .json(input)))
            }

            /// Turns a schedule on.
            ///
            /// `POST /dns64/groups/schedules/{id}/enable`
            public func enable(_ id: Int) async throws {
                try await client.sendWithoutContent(Request(.post, "/dns64/groups/schedules/\(id)/enable"))
            }

            /// Turns a schedule off.
            ///
            /// `POST /dns64/groups/schedules/{id}/disable`
            public func disable(_ id: Int) async throws {
                try await client.sendWithoutContent(Request(.post, "/dns64/groups/schedules/\(id)/disable"))
            }

            /// Deletes a schedule.
            ///
            /// `DELETE /dns64/groups/schedules/{id}`
            public func delete(_ id: Int) async throws {
                try await client.sendWithoutContent(Request(.delete, "/dns64/groups/schedules/\(id)"))
            }
        }
    }
}
