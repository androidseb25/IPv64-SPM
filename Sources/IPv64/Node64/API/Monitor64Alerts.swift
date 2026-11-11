import Foundation

extension Node64.Monitor64 {
    /// Problems with history.
    public var problems: Problems { Problems(client: client) }
    /// Thresholds (rules) and their overrides per group or tag.
    public var rules: Rules { Rules(client: client) }
    /// Notification settings and their overrides per group or tag.
    public var notify: Notify { Notify(client: client) }
    /// Maintenance windows.
    public var maintenance: Maintenance { Maintenance(client: client) }

    /// Problem endpoints of Monitor64.
    public struct Problems: Sendable { let client: Node64 }
    /// Threshold endpoints of Monitor64.
    public struct Rules: Sendable { let client: Node64 }
    /// Notification endpoints of Monitor64.
    public struct Notify: Sendable { let client: Node64 }
    /// Maintenance endpoints of Monitor64.
    public struct Maintenance: Sendable { let client: Node64 }
}

private struct UIDResult: Decodable, Sendable { let uid: String }
private struct MoveBody: Encodable, Sendable { let dir: Node64.Monitor64MoveDirection }
private struct StdBody: Encodable, Sendable { let rules: [String: Node64.Monitor64Rule] }

private struct PreviewBody: Encodable, Sendable {
    let input: Node64.Monitor64RuleOverrideInput
    let uid: String?

    enum CodingKeys: String, CodingKey { case uid }

    func encode(to encoder: any Encoder) throws {
        try input.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(uid, forKey: .uid)
    }
}

// MARK: - Problems

extension Node64.Monitor64.Problems {
    /// Problems, newest first (at most 5000). Answers `404` if the module is off.
    ///
    /// - Parameters:
    ///   - status: `open` (default), `closed` or `all`.
    ///   - range: Period (open or closed within it; default `7d`; any other value means no limit).
    ///   - who: Involved: `system`, `api` or `user:<uid|name>`.
    ///   - query: Search in host, service, involved and acknowledgement comment (query parameter `q`).
    ///   - host: UID of the host.
    ///
    /// `GET /monitor64/problems`
    public func list(
        status: Node64.Monitor64ProblemListStatus? = nil,
        range: Node64.Monitor64ProblemListRange? = nil,
        who: String? = nil,
        query: String? = nil,
        host: String? = nil
    ) async throws -> Node64.Monitor64ProblemList {
        try await client.send(Request(.get, "/monitor64/problems", query: [
            QueryItem("status", status),
            QueryItem("range", range),
            QueryItem("who", who),
            QueryItem("q", query),
            QueryItem("host", host),
        ]))
    }

    /// The same list as CSV: semicolon separated, UTF-8 with BOM (kept in the string), times in the time zone
    /// of the user, headings in their language. Cells starting with `= + - @` get a leading `'`. Filters as for ``list(status:range:who:query:host:)``.
    ///
    /// `GET /monitor64/problems.csv`
    public func csv(
        status: Node64.Monitor64ProblemListStatus? = nil,
        range: Node64.Monitor64ProblemListRange? = nil,
        who: String? = nil,
        query: String? = nil,
        host: String? = nil
    ) async throws -> String {
        try await client.sendText(Request(.get, "/monitor64/problems.csv", query: [
            QueryItem("status", status),
            QueryItem("range", range),
            QueryItem("who", who),
            QueryItem("q", query),
            QueryItem("host", host),
        ]), accept: "text/csv")
    }

    /// A problem with its history and the channel names.
    ///
    /// - Parameter uid: UID of the problem.
    ///
    /// `GET /monitor64/problems/{uid}`
    public func get(_ uid: String) async throws -> Node64.Monitor64ProblemDetail {
        try await client.send(Request(.get, "/monitor64/problems/\(uid)"))
    }

    /// Acknowledges, un-acknowledges, comments on or resolves the open problem of a host and service.
    /// After `resolve` the host is evaluated again at once. Acknowledging or resolving the service `traps` resets the open traps.
    ///
    /// `POST /monitor64/problems/action`
    @discardableResult
    public func perform(_ action: Node64.Monitor64ProblemAction) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.post, "/monitor64/problems/action", body: .json(action)))
    }
}

// MARK: - Rules

extension Node64.Monitor64.Rules {
    /// Rule kinds, built-in and effective defaults, overrides per group or tag (topmost wins) with their effect, and the thresholds set on hosts.
    ///
    /// `GET /monitor64/rules`
    public func get() async throws -> Node64.Monitor64Rules {
        try await client.send(Request(.get, "/monitor64/rules"))
    }

    /// Replaces the changes to the built-in default: only kinds in `rules` that differ from the built-in
    /// default are stored, kinds not named are built-in again afterwards. All hosts are evaluated again at once.
    ///
    /// - Parameter rules: Rule kind to rule (fields override the built-in default).
    ///
    /// `PUT /monitor64/rules/std`
    @discardableResult
    public func updateStandard(_ rules: [String: Node64.Monitor64Rule]) async throws -> Node64.Monitor64RuleStdResult {
        try await client.send(Request(.put, "/monitor64/rules/std", body: .json(StdBody(rules: rules))))
    }

    /// Effect of a new or changed override on the current state; nothing is stored.
    ///
    /// - Parameters:
    ///   - input: The override.
    ///   - uid: Existing override that it replaces.
    ///
    /// `POST /monitor64/rules/preview`
    public func preview(_ input: Node64.Monitor64RuleOverrideInput, replacing uid: String? = nil) async throws -> Node64.Monitor64Effect {
        try await client.send(Request(.post, "/monitor64/rules/preview", body: .json(PreviewBody(input: input, uid: uid))))
    }

    /// Adds an override at the bottom. All hosts are evaluated again at once. Returns the UID.
    ///
    /// `POST /monitor64/rules/overrides`
    public func createOverride(_ input: Node64.Monitor64RuleOverrideInput) async throws -> String {
        let result: UIDResult = try await client.send(Request(.post, "/monitor64/rules/overrides", body: .json(input)))
        return result.uid
    }

    /// Replaces an override; its position stays. Returns the UID.
    ///
    /// `PUT /monitor64/rules/overrides/{uid}`
    public func updateOverride(_ uid: String, _ input: Node64.Monitor64RuleOverrideInput) async throws -> String {
        let result: UIDResult = try await client.send(Request(.put, "/monitor64/rules/overrides/\(uid)", body: .json(input)))
        return result.uid
    }

    /// Removes an override.
    ///
    /// `DELETE /monitor64/rules/overrides/{uid}`
    @discardableResult
    public func deleteOverride(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.delete, "/monitor64/rules/overrides/\(uid)"))
    }

    /// Moves an override one place up or down (the topmost wins); at the edge nothing happens.
    ///
    /// `POST /monitor64/rules/overrides/{uid}/move`
    @discardableResult
    public func moveOverride(_ uid: String, _ direction: Node64.Monitor64MoveDirection) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.post, "/monitor64/rules/overrides/\(uid)/move", body: .json(MoveBody(dir: direction))))
    }
}

// MARK: - Notify

extension Node64.Monitor64.Notify {
    /// Basic settings (channels by severity, reminders), channels of the node, overrides per group or tag and the quiet hours.
    ///
    /// `GET /monitor64/notify`
    public func get() async throws -> Node64.Monitor64Notify {
        try await client.send(Request(.get, "/monitor64/notify"))
    }

    /// Saves the basic settings (replaces them). Channels without warn and crit are dropped, duplicates count once.
    ///
    /// `PUT /monitor64/notify`
    @discardableResult
    public func update(_ config: Node64.Monitor64NotifyConfig) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.put, "/monitor64/notify", body: .json(config)))
    }

    /// Sends a sample problem to all channels of the basic settings (warn and crit). Answers `503` if it cannot be sent.
    ///
    /// `POST /monitor64/notify/test`
    public func test() async throws -> Node64.Monitor64NotifyTestResult {
        try await client.send(Request(.post, "/monitor64/notify/test"))
    }

    /// Adds an override at the bottom. Returns the UID.
    ///
    /// `POST /monitor64/notify/overrides`
    public func createOverride(_ input: Node64.Monitor64NotifyOverrideInput) async throws -> String {
        let result: UIDResult = try await client.send(Request(.post, "/monitor64/notify/overrides", body: .json(input)))
        return result.uid
    }

    /// Replaces an override; its position stays. Returns the UID.
    ///
    /// `PUT /monitor64/notify/overrides/{uid}`
    public func updateOverride(_ uid: String, _ input: Node64.Monitor64NotifyOverrideInput) async throws -> String {
        let result: UIDResult = try await client.send(Request(.put, "/monitor64/notify/overrides/\(uid)", body: .json(input)))
        return result.uid
    }

    /// Removes an override.
    ///
    /// `DELETE /monitor64/notify/overrides/{uid}`
    @discardableResult
    public func deleteOverride(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.delete, "/monitor64/notify/overrides/\(uid)"))
    }

    /// Moves an override one place up or down (the topmost wins).
    ///
    /// `POST /monitor64/notify/overrides/{uid}/move`
    @discardableResult
    public func moveOverride(_ uid: String, _ direction: Node64.Monitor64MoveDirection) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.post, "/monitor64/notify/overrides/\(uid)/move", body: .json(MoveBody(dir: direction))))
    }
}

// MARK: - Maintenance

extension Node64.Monitor64.Maintenance {
    /// Windows with state (running, planned, recurring, ended), plus hosts, groups and tags to choose from and the time zone of the node.
    ///
    /// `GET /monitor64/maintenance`
    public func list() async throws -> Node64.Monitor64MaintList {
        try await client.send(Request(.get, "/monitor64/maintenance"))
    }

    /// Creates a window. Problems in maintenance are not reported; all hosts are evaluated again at once. Returns the UID.
    ///
    /// `POST /monitor64/maintenance`
    public func create(_ input: Node64.Monitor64MaintInput) async throws -> String {
        let result: UIDResult = try await client.send(Request(.post, "/monitor64/maintenance", body: .json(input)))
        return result.uid
    }

    /// Replaces a window. Returns the UID.
    ///
    /// `PUT /monitor64/maintenance/{uid}`
    public func update(_ uid: String, _ input: Node64.Monitor64MaintInput) async throws -> String {
        let result: UIDResult = try await client.send(Request(.put, "/monitor64/maintenance/\(uid)", body: .json(input)))
        return result.uid
    }

    /// Removes a window.
    ///
    /// `DELETE /monitor64/maintenance/{uid}`
    @discardableResult
    public func delete(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.delete, "/monitor64/maintenance/\(uid)"))
    }

    /// Ends a window now. Recurring windows end for good.
    ///
    /// `POST /monitor64/maintenance/{uid}/end`
    @discardableResult
    public func end(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.post, "/monitor64/maintenance/\(uid)/end"))
    }
}
