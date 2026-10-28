import Foundation

extension Node64.Proxy64.Streams {
    /// TCP/UDP streams.
    ///
    /// `GET /cdn64/streams`
    public func list() async throws -> [Node64.ProxyStream] {
        try await client.send(Request(.get, "/cdn64/streams"))
    }

    /// Creates a stream.
    ///
    /// Fails with 422 for invalid fields, a duplicate port or a port of the shared entry point.
    ///
    /// `POST /cdn64/streams`
    public func create(_ input: Node64.ProxyStreamInput) async throws -> Node64.ProxyStream {
        try await client.send(Request(.post, "/cdn64/streams", body: .json(input)))
    }

    /// A single stream.
    ///
    /// `GET /cdn64/streams/{id}`
    public func get(_ id: Int) async throws -> Node64.ProxyStream {
        try await client.send(Request(.get, "/cdn64/streams/\(id)"))
    }

    /// Changes a stream. Fields you leave `nil` stay unchanged.
    ///
    /// `PUT /cdn64/streams/{id}`
    public func update(_ id: Int, _ input: Node64.ProxyStreamInput) async throws -> Node64.ProxyStream {
        try await client.send(Request(.put, "/cdn64/streams/\(id)", body: .json(input)))
    }

    /// Deletes a stream.
    ///
    /// `DELETE /cdn64/streams/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/streams/\(id)"))
    }

    /// Switches a stream on.
    ///
    /// `POST /cdn64/streams/{id}/enable`
    public func enable(_ id: Int) async throws -> Node64.ProxyStream {
        try await client.send(Request(.post, "/cdn64/streams/\(id)/enable"))
    }

    /// Switches a stream off.
    ///
    /// `POST /cdn64/streams/{id}/disable`
    public func disable(_ id: Int) async throws -> Node64.ProxyStream {
        try await client.send(Request(.post, "/cdn64/streams/\(id)/disable"))
    }

    /// Creates a health check for the target of this stream (module Healthchecks).
    ///
    /// Fails with 422 if the stream has no target or the Healthchecks module is off.
    ///
    /// `POST /cdn64/streams/{id}/healthcheck`
    public func createHealthcheck(_ id: Int) async throws -> Node64.Proxy64HealthcheckResult {
        try await client.send(Request(.post, "/cdn64/streams/\(id)/healthcheck"))
    }
}
