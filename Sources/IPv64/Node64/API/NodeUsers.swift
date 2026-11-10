import Foundation

// MARK: - Users

extension Node64.Node {
    /// Users of the node.
    public var users: Users { Users(client: client) }

    /// Endpoints for the users of the node (`/users`).
    public struct Users: Sendable {
        let client: Node64

        /// Lists the users of this node (without password hash and secrets).
        ///
        /// `GET /users`
        public func list() async throws -> [Node64.NodeUser] {
            try await client.send(Request(.get, "/users"))
        }

        /// Deletes another user. Your own user cannot be deleted (`409`); `404` for an unknown user.
        ///
        /// With the cluster area "users" switched on, the user is also deleted on the other nodes.
        ///
        /// - Parameter id: Numeric user ID.
        ///
        /// `DELETE /users/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/users/\(id)"))
        }

        /// The signed-in user, or the owner of the API key.
        ///
        /// `GET /users/me`
        public func me() async throws -> Node64.NodeUser {
            try await client.send(Request(.get, "/users/me"))
        }

        /// Changes your own language and time zone. Omitted fields stay unchanged (partial update).
        ///
        /// The time zone also applies to the node. Fails with `422` for an unknown language or time zone.
        ///
        /// - Parameters:
        ///   - language: `de` or `en`.
        ///   - timezone: IANA time zone, e.g. `Europe/Berlin`.
        ///
        /// `PUT /users/me`
        public func updateMe(language: Node64.NodeUserLanguage? = nil, timezone: String? = nil) async throws -> Node64.NodeUser {
            try await client.send(Request(.put, "/users/me", body: .json(MeBody(lang: language, timezone: timezone))))
        }

        private struct MeBody: Encodable, Sendable {
            let lang: Node64.NodeUserLanguage?
            let timezone: String?
        }
    }
}

// MARK: - MCP

extension Node64.Node {
    /// The MCP interface (AI access) of the node.
    public var mcp: MCP { MCP(client: client) }

    /// Endpoints for the MCP interface of the node (`/mcp`).
    public struct MCP: Sendable {
        let client: Node64

        /// Switch, areas and own keys of the MCP interface.
        ///
        /// `GET /mcp`
        public func get() async throws -> Node64.NodeMCP {
            try await client.send(Request(.get, "/mcp"))
        }

        /// Switches MCP on or off. Fails with `422` when `enabled` is missing.
        ///
        /// - Returns: The state like ``get()``.
        ///
        /// `PUT /mcp`
        public func setEnabled(_ enabled: Bool) async throws -> Node64.NodeMCP {
            try await client.send(Request(.put, "/mcp", body: .json(EnabledBody(enabled: enabled))))
        }

        /// Creates an MCP key (read access only). The key (`mcp64_…`) is only part of this response; store it securely.
        ///
        /// Fails with `422` for an invalid name or areas.
        ///
        /// - Parameters:
        ///   - name: Name of the key, 1–100 characters.
        ///   - areas: Areas from ``get()`` (``Node64/NodeMCPArea/name``).
        ///
        /// `POST /mcp/keys`
        public func createKey(name: String, areas: [String]) async throws -> Node64.NodeCreatedMCPKey {
            try await client.send(Request(.post, "/mcp/keys", body: .json(KeyBody(name: name, areas: areas))))
        }

        /// Revokes one of your own MCP keys. Fails with `404` for an unknown key.
        ///
        /// - Parameter id: Numeric key ID.
        ///
        /// `DELETE /mcp/keys/{id}`
        public func deleteKey(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/mcp/keys/\(id)"))
        }

        private struct EnabledBody: Encodable, Sendable {
            let enabled: Bool
        }

        private struct KeyBody: Encodable, Sendable {
            let name: String
            let areas: [String]
        }
    }
}

// MARK: - Self-update

extension Node64.Node {
    /// Self-update of the node.
    public var update: Update { Update(client: client) }

    /// Endpoints for the self-update of the node (`/update`). `404` when self-update is not available.
    public struct Update: Sendable {
        let client: Node64

        /// Running version, origin, settings and the last check result.
        ///
        /// The spec describes the object only in prose (Mode, Channel, Chosen, Window, Modes, Channels, Latest; the exact key spelling is unverified, inspect the raw keys),
        /// so the raw JSON is returned (spec gap).
        ///
        /// `GET /update`
        public func get() async throws -> JSONValue {
            try await client.sendJSON(Request(.get, "/update"))
        }

        /// Checks for updates now. Fails with `502` when the check failed.
        ///
        /// Raw JSON like ``get()`` (spec gap).
        ///
        /// `POST /update/check`
        public func check() async throws -> JSONValue {
            try await client.sendJSON(Request(.post, "/update/check"))
        }

        /// Installs the newest version of the channel. **The node restarts.**
        ///
        /// Installation runs in the background (`202`). Errors: `409` already up to date or an update is running,
        /// `502` the check failed.
        ///
        /// `POST /update/apply`
        public func apply() async throws -> Node64.NodeUpdateStatus {
            try await client.send(Request(.post, "/update/apply"))
        }

        /// Goes back to the version from the image. **The node restarts.**
        ///
        /// `POST /update/reset`
        public func reset() async throws -> Node64.NodeUpdateStatus {
            try await client.send(Request(.post, "/update/reset"))
        }

        /// Changes the update settings. Omitted fields stay unchanged (partial update).
        ///
        /// `channel: auto` withdraws your own choice (the node then follows the running version).
        /// Fails with `422` for an invalid value. Raw JSON like ``get()`` (spec gap).
        ///
        /// - Parameters:
        ///   - mode: `off`, `notify` or `auto`.
        ///   - channel: `stable`, `preview` or `auto`.
        ///   - window: Time window for automatic updates, e.g. `03:00-05:00`.
        ///
        /// `PUT /update/settings`
        public func updateSettings(
            mode: Node64.NodeUpdateMode? = nil,
            channel: Node64.NodeUpdateChannel? = nil,
            window: String? = nil
        ) async throws -> JSONValue {
            try await client.sendJSON(Request(.put, "/update/settings", body: .json(SettingsBody(mode: mode, channel: channel, window: window))))
        }

        private struct SettingsBody: Encodable, Sendable {
            let mode: Node64.NodeUpdateMode?
            let channel: Node64.NodeUpdateChannel?
            let window: String?
        }
    }
}

extension Node64 {
    /// Language of a user.
    public struct NodeUserLanguage: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// German.
        public static let de: NodeUserLanguage = "de"
        /// English.
        public static let en: NodeUserLanguage = "en"
    }

    /// A user of the node (no password hash, no secrets).
    public struct NodeUser: Codable, Hashable, Sendable, Identifiable {
        /// Numeric user ID.
        public let id: Int
        /// ID of the user in the cluster.
        public let uid: String?
        /// User name.
        public let username: String?
        /// Language.
        public let lang: NodeUserLanguage?
        /// Time zone (IANA).
        public let timezone: String?
        /// Two-factor authentication is set up.
        public let totp: Bool?
        /// This is the signed-in user or the owner of the API key.
        public let isSelf: Bool?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last login.
        public let lastLoginAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, uid, username, lang, timezone, totp
            case isSelf = "self"
            case createdAt = "created_at"
            case lastLoginAt = "last_login_at"
        }
    }

    /// State of the MCP interface (result of ``Node64/Node/MCP/get()``).
    public struct NodeMCP: Codable, Hashable, Sendable {
        /// MCP is switched on.
        public let enabled: Bool?
        /// URL path of the MCP endpoint.
        public let path: String?
        /// Requests allowed per minute.
        public let ratePerMinute: Int?
        /// Areas a key can be restricted to.
        public let areas: [NodeMCPArea]?
        /// Your own keys.
        public let keys: [NodeMCPKey]?

        enum CodingKeys: String, CodingKey {
            case enabled, path, areas, keys
            case ratePerMinute = "rate_per_minute"
        }
    }

    /// An area of the MCP interface.
    public struct NodeMCPArea: Codable, Hashable, Sendable, Identifiable {
        /// Area name.
        public let name: String?
        /// The area is available on this node.
        public let available: Bool?

        public var id: String { name ?? "" }
    }

    /// An MCP key (without the key itself).
    public struct NodeMCPKey: Codable, Hashable, Sendable, Identifiable {
        /// Numeric key ID.
        public let id: Int
        /// Name of the key.
        public let name: String?
        /// Short hint to recognize the key.
        public let hint: String?
        /// Areas the key may read.
        public let areas: [String]?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last use.
        public let lastUsedAt: Date?
        /// IP address of the last use.
        public let lastIP: String?

        enum CodingKeys: String, CodingKey {
            case id, name, hint, areas
            case createdAt = "created_at"
            case lastUsedAt = "last_used_at"
            case lastIP = "last_ip"
        }
    }

    /// Result of ``Node64/Node/MCP/createKey(name:areas:)``.
    public struct NodeCreatedMCPKey: Codable, Hashable, Sendable, Identifiable {
        /// Numeric key ID.
        public let id: Int
        /// Name of the key.
        public let name: String?
        /// Short hint to recognize the key.
        public let hint: String?
        /// Areas the key may read.
        public let areas: [String]?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last use.
        public let lastUsedAt: Date?
        /// IP address of the last use.
        public let lastIP: String?
        /// The secret key (`mcp64_…`). It is shown only once; store it securely.
        public let key: String?

        enum CodingKeys: String, CodingKey {
            case id, name, hint, areas, key
            case createdAt = "created_at"
            case lastUsedAt = "last_used_at"
            case lastIP = "last_ip"
        }
    }

    /// Mode of the self-update.
    public struct NodeUpdateMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// No update check.
        public static let off: NodeUpdateMode = "off"
        /// Check and notify.
        public static let notify: NodeUpdateMode = "notify"
        /// Install automatically in the time window.
        public static let auto: NodeUpdateMode = "auto"
    }

    /// Update channel of the self-update.
    public struct NodeUpdateChannel: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Stable releases.
        public static let stable: NodeUpdateChannel = "stable"
        /// Preview releases.
        public static let preview: NodeUpdateChannel = "preview"
        /// Withdraw the own choice and follow the running version.
        public static let auto: NodeUpdateChannel = "auto"
    }

    /// Result of ``Node64/Node/Update/apply()`` and ``Node64/Node/Update/reset()`` (`202`).
    public struct NodeUpdateStatus: Codable, Hashable, Sendable {
        /// `restarting`.
        public let status: String?
        /// Version being installed (only for `apply`).
        public let version: String?
    }
}
