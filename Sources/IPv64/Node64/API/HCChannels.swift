import Foundation

extension Node64.HC {
    /// Notification channels and the delivery log.
    public var channels: Channels { Channels(client: client) }

    /// Endpoints of the *Benachrichtigungen* area.
    public struct Channels: Sendable { let client: Node64 }
}

extension Node64.HC.Channels {
    /// Lists all notification channels.
    ///
    /// - Parameter includeSecrets: `true` returns secrets in `config` unmasked (sent as `true`).
    ///
    /// `GET /channels`
    public func list(includeSecrets: Bool? = nil) async throws -> [Node64.Channel] {
        try await client.send(Request(.get, "/channels", query: [QueryItem("include_secrets", includeSecrets)]))
    }

    /// Returns one channel.
    ///
    /// `GET /channels/{id}`
    public func get(_ id: Int) async throws -> Node64.Channel {
        try await client.send(Request(.get, "/channels/\(id)"))
    }

    /// Creates a channel, e.g. type `telegram` with `bot_token` and `chat_id` in `config`.
    ///
    /// `POST /channels`
    public func create(_ input: Node64.ChannelInput) async throws -> Node64.Channel {
        try await client.send(Request(.post, "/channels", body: .json(input)))
    }

    /// Changes a channel. Empty secrets in `config` keep the stored value.
    ///
    /// Channels with `execution == .server` only allow changing name and switches. The spec does not
    /// say whether omitted fields are kept, so send the complete channel (start from ``get(_:)``).
    /// The spec documents no response body, so the raw JSON is returned (spec gap).
    ///
    /// `PUT /channels/{id}`
    @discardableResult
    public func update(_ id: Int, _ input: Node64.ChannelInput) async throws -> JSONValue {
        try await client.sendJSON(Request(.put, "/channels/\(id)", body: .json(input)))
    }

    /// Deletes a channel.
    ///
    /// `DELETE /channels/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/channels/\(id)"))
    }

    /// Sends a test message through the channel.
    ///
    /// The node answers `502` with `{ok: false, error}` when delivery fails; that surfaces as ``Node64Error``.
    ///
    /// `POST /channels/{id}/test`
    public func sendTest(_ id: Int) async throws -> Node64.ChannelTestResult {
        try await client.send(Request(.post, "/channels/\(id)/test"))
    }

    /// Channel types with their fields.
    ///
    /// The spec documents no response body, so the raw JSON is returned (spec gap).
    ///
    /// `GET /channel-types`
    public func types() async throws -> JSONValue {
        try await client.sendJSON(Request(.get, "/channel-types"))
    }

    /// Delivery log, newest first.
    ///
    /// To page, pass the `id` of the last item as `before`.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of entries.
    ///   - before: Only entries with a smaller ID.
    ///   - channel: Only entries of this channel ID.
    ///
    /// `GET /deliveries`
    public func deliveries(limit: Int? = nil, before: Int? = nil, channel: Int? = nil) async throws -> [Node64.Delivery] {
        try await client.send(Request(.get, "/deliveries", query: [
            QueryItem("limit", limit), QueryItem("before", before), QueryItem("channel", channel),
        ]))
    }
}
