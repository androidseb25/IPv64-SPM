import Foundation

extension Node64.Link {
    /// Status of the healthchecks sync with ipv64.
    ///
    /// `GET /link`
    public func status() async throws -> Node64.LinkStatus {
        try await client.send(Request(.get, "/link"))
    }

    /// Links the node with one click using the central ipv64 API key.
    ///
    /// Needs a stored key (``storeIPv64Key(_:)``) and waits up to 10 seconds for the node token. The server may
    /// answer `202` when the code is redeemed and the token follows in the background; poll ``status()`` then.
    /// Errors: `401` ipv64 rejected the key, `409` already linked or no key, `502` hub/ipv64 unreachable.
    ///
    /// - Parameters:
    ///   - location: Location of the node.
    ///   - remoteManagement: Remote management in the portal (server default `full`).
    ///
    /// `POST /link/apikey`
    public func connect(
        location: String? = nil,
        remoteManagement: Node64.LinkRemoteManagement? = nil
    ) async throws -> Node64.LinkStatus {
        try await client.send(Request(
            .post, "/link/apikey",
            body: .json(ConnectBody(location: location, remoteMgmt: remoteManagement))
        ))
    }

    /// Cuts the link to ipv64. Fails with `502` if disconnecting failed.
    ///
    /// - Parameter keepChecks: Keep the checks locally. Otherwise online checks and foreign checks are removed.
    ///
    /// `POST /link/unlink`
    public func unlink(keepChecks: Bool? = nil) async throws {
        try await client.sendWithoutContent(Request(.post, "/link/unlink", body: .json(UnlinkBody(keepChecks: keepChecks))))
    }

    /// Lists open conflicts with the local and the server version.
    ///
    /// `GET /link/conflicts`
    public func conflicts() async throws -> [Node64.LinkConflict] {
        try await client.send(Request(.get, "/link/conflicts"))
    }

    /// Resolves a conflict. Fails with `422` for an unknown conflict.
    ///
    /// - Parameters:
    ///   - id: Conflict ID.
    ///   - keep: Which version wins (server default: server).
    ///
    /// `POST /link/conflicts/{id}`
    public func resolveConflict(_ id: String, keep: Node64.LinkConflictResolution? = nil) async throws {
        try await client.sendWithoutContent(Request(.post, "/link/conflicts/\(id)", body: .json(ResolveBody(keep: keep))))
    }

    /// Resolves a conflict by its numeric ID.
    ///
    /// `POST /link/conflicts/{id}`
    public func resolveConflict(_ id: Int, keep: Node64.LinkConflictResolution? = nil) async throws {
        try await resolveConflict(String(id), keep: keep)
    }

    /// Changes the sync settings. Takes effect immediately.
    ///
    /// - Parameter localNotifications: Also send server channels locally.
    /// - Returns: The current settings.
    ///
    /// `PUT /link/settings`
    public func updateSettings(localNotifications: Bool? = nil) async throws -> Node64.LinkSettings {
        try await client.send(Request(.put, "/link/settings", body: .json(SettingsBody(localNotifications: localNotifications))))
    }

    /// Shows the central ipv64 API key: account, plan, expiry. The key itself is never returned.
    ///
    /// `GET /ipv64`
    public func ipv64Account() async throws -> Node64.IPv64LinkAccount {
        try await client.send(Request(.get, "/ipv64"))
    }

    /// Stores the ipv64 API key. It is verified at ipv64 and stored encrypted.
    ///
    /// Errors: `422` wrong format or rejected by ipv64, `502` ipv64 unreachable.
    ///
    /// `PUT /ipv64/key`
    public func storeIPv64Key(_ key: String) async throws -> Node64.IPv64LinkAccount {
        try await client.send(Request(.put, "/ipv64/key", body: .json(KeyBody(key: key))))
    }

    /// Removes the stored ipv64 API key.
    ///
    /// `DELETE /ipv64/key`
    public func removeIPv64Key() async throws {
        try await client.sendWithoutContent(Request(.delete, "/ipv64/key"))
    }

    private struct ConnectBody: Encodable, Sendable {
        let location: String?
        let remoteMgmt: Node64.LinkRemoteManagement?

        enum CodingKeys: String, CodingKey {
            case location
            case remoteMgmt = "remote_mgmt"
        }
    }

    private struct UnlinkBody: Encodable, Sendable {
        let keepChecks: Bool?

        enum CodingKeys: String, CodingKey {
            case keepChecks = "keep_checks"
        }
    }

    private struct ResolveBody: Encodable, Sendable {
        let keep: Node64.LinkConflictResolution?
    }

    private struct SettingsBody: Encodable, Sendable {
        let localNotifications: Bool?

        enum CodingKeys: String, CodingKey {
            case localNotifications = "local_notifications"
        }
    }

    private struct KeyBody: Encodable, Sendable {
        let key: String
    }
}
