import Foundation

extension Node64.HC {
    /// Online checks in API mode: the node has an ipv64 API key but no healthchecks sync, so
    /// requests go to the ipv64 API v2. With sync, online checks are normal checks under
    /// ``checks`` (execution `online`); these endpoints then answer `409`.
    public var onlineChecks: OnlineChecks { OnlineChecks(client: client) }

    /// Endpoints below `/online-checks`.
    public struct OnlineChecks: Sendable { let client: Node64 }
}

extension Node64.HC.OnlineChecks {
    /// Online checks of the account (API mode only, otherwise `409`; `502` if ipv64 is unreachable).
    ///
    /// `GET /online-checks`
    public func list() async throws -> [Node64.Check] {
        try await client.send(Request(.get, "/online-checks"))
    }

    /// Creates an online check (API mode only). Same fields as ``Node64/HC/Checks/create(_:)``;
    /// channels and parent check do not apply at ipv64. Fails with `422` when invalid or the limit is reached.
    ///
    /// `POST /online-checks`
    public func create(_ check: Node64.CheckInput) async throws -> Node64.Check {
        try await client.send(Request(.post, "/online-checks", body: .json(check)))
    }

    /// Reads an online check (API mode).
    ///
    /// `GET /online-checks/{token}`
    public func get(_ token: String) async throws -> Node64.Check {
        try await client.send(Request(.get, "/online-checks/\(token)"))
    }

    /// Changes an online check (API mode). Fails with `422` when invalid or the limit is reached.
    ///
    /// `PUT /online-checks/{token}`
    public func update(_ token: String, _ check: Node64.CheckInput) async throws -> Node64.Check {
        try await client.send(Request(.put, "/online-checks/\(token)", body: .json(check)))
    }

    /// Deletes an online check (API mode).
    ///
    /// `DELETE /online-checks/{token}`
    public func delete(_ token: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/online-checks/\(token)"))
    }

    /// Pauses, resumes or runs an online check now (API mode). Answers `202` without content;
    /// an unknown action gives `404`.
    ///
    /// `POST /online-checks/{token}/{action}`
    public func perform(_ token: String, action: Node64.OnlineCheckAction) async throws {
        try await client.sendWithoutContent(Request(.post, "/online-checks/\(token)/\(action.rawValue)"))
    }

    /// Pauses an online check (API mode).
    ///
    /// `POST /online-checks/{token}/pause`
    public func pause(_ token: String) async throws {
        try await perform(token, action: .pause)
    }

    /// Resumes an online check (API mode).
    ///
    /// `POST /online-checks/{token}/resume`
    public func resume(_ token: String) async throws {
        try await perform(token, action: .resume)
    }

    /// Measures an online check now (API mode).
    ///
    /// `POST /online-checks/{token}/run`
    public func run(_ token: String) async throws {
        try await perform(token, action: .run)
    }
}
