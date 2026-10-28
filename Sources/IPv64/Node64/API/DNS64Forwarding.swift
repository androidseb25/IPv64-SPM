import Foundation

extension Node64.DNS64 {
    /// Forwards.
    public var forwards: Forwards { Forwards(client: client) }

    /// Endpoints of `/dns64/forwards`.
    public struct Forwards: Sendable {
        let client: Node64

        /// Lists the forwards.
        ///
        /// `GET /dns64/forwards`
        public func list() async throws -> [Node64.DNS64Forward] {
            try await client.send(Request(.get, "/dns64/forwards"))
        }

        /// Creates a forward.
        ///
        /// `POST /dns64/forwards`
        public func create(_ input: Node64.DNS64ForwardInput) async throws -> Node64.DNS64Forward {
            try await client.send(Request(.post, "/dns64/forwards", body: .json(input)))
        }

        /// Changes a forward. The on/off state stays as it is.
        ///
        /// Sends the complete forward (`domain` and `servers` are required); build `input` from the
        /// current forward and change what you need.
        ///
        /// `PUT /dns64/forwards/{id}`
        public func update(_ id: Int, _ input: Node64.DNS64ForwardInput) async throws -> Node64.DNS64Forward {
            try await client.send(Request(.put, "/dns64/forwards/\(id)", body: .json(input)))
        }

        /// Deletes a forward.
        ///
        /// `DELETE /dns64/forwards/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/dns64/forwards/\(id)"))
        }

        /// Turns a forward on.
        ///
        /// `POST /dns64/forwards/{id}/enable`
        public func enable(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/forwards/\(id)/enable"))
        }

        /// Turns a forward off.
        ///
        /// `POST /dns64/forwards/{id}/disable`
        public func disable(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/forwards/\(id)/disable"))
        }

        /// Tests a forward by asking its servers for the SOA of the domain. Also works for disabled forwards.
        ///
        /// `POST /dns64/forwards/{id}/test`
        public func test(_ id: Int) async throws -> Node64.DNS64ForwardTestResult {
            try await client.send(Request(.post, "/dns64/forwards/\(id)/test"))
        }
    }
}

extension Node64.DNS64 {
    /// Rewrites.
    public var rewrites: Rewrites { Rewrites(client: client) }

    /// Endpoints of `/dns64/rewrites`.
    public struct Rewrites: Sendable {
        let client: Node64

        /// Lists the rewrites.
        ///
        /// `GET /dns64/rewrites`
        public func list() async throws -> [Node64.DNS64Rewrite] {
            try await client.send(Request(.get, "/dns64/rewrites"))
        }

        /// Creates a rewrite.
        ///
        /// `POST /dns64/rewrites`
        public func create(_ input: Node64.DNS64RewriteInput) async throws -> Node64.DNS64Rewrite {
            try await client.send(Request(.post, "/dns64/rewrites", body: .json(input)))
        }

        /// Changes a rewrite. The on/off state stays as it is.
        ///
        /// Sends the complete rewrite (`name` and `target` are required); build `input` from the
        /// current rewrite and change what you need.
        ///
        /// `PUT /dns64/rewrites/{id}`
        public func update(_ id: Int, _ input: Node64.DNS64RewriteInput) async throws -> Node64.DNS64Rewrite {
            try await client.send(Request(.put, "/dns64/rewrites/\(id)", body: .json(input)))
        }

        /// Deletes a rewrite.
        ///
        /// `DELETE /dns64/rewrites/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/dns64/rewrites/\(id)"))
        }

        /// Turns a rewrite on.
        ///
        /// `POST /dns64/rewrites/{id}/enable`
        public func enable(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/rewrites/\(id)/enable"))
        }

        /// Turns a rewrite off.
        ///
        /// `POST /dns64/rewrites/{id}/disable`
        public func disable(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/rewrites/\(id)/disable"))
        }
    }
}

extension Node64.DNS64 {
    /// Local zones.
    public var zones: Zones { Zones(client: client) }

    /// Endpoints of `/dns64/zones`.
    public struct Zones: Sendable {
        let client: Node64

        /// Lists the local zones.
        ///
        /// `GET /dns64/zones`
        public func list() async throws -> [Node64.DNS64Zone] {
            try await client.send(Request(.get, "/dns64/zones"))
        }

        /// Creates a local zone.
        ///
        /// `POST /dns64/zones`
        public func create(_ input: Node64.DNS64ZoneInput) async throws -> Node64.DNS64Zone {
            try await client.send(Request(.post, "/dns64/zones", body: .json(input)))
        }

        /// Changes a local zone. The on/off state stays as it is.
        ///
        /// Sends the complete zone (`name` is required); build `input` from the current zone and
        /// change what you need.
        ///
        /// `PUT /dns64/zones/{id}`
        public func update(_ id: Int, _ input: Node64.DNS64ZoneInput) async throws -> Node64.DNS64Zone {
            try await client.send(Request(.put, "/dns64/zones/\(id)", body: .json(input)))
        }

        /// Deletes a local zone.
        ///
        /// `DELETE /dns64/zones/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/dns64/zones/\(id)"))
        }

        /// Turns a local zone on.
        ///
        /// `POST /dns64/zones/{id}/enable`
        public func enable(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/zones/\(id)/enable"))
        }

        /// Turns a local zone off.
        ///
        /// `POST /dns64/zones/{id}/disable`
        public func disable(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.post, "/dns64/zones/\(id)/disable"))
        }

        /// Returns the zone file of a zone in BIND format.
        ///
        /// `GET /dns64/zones/{id}/zonefile`
        public func zonefile(_ id: Int) async throws -> String {
            try await client.sendText(Request(.get, "/dns64/zones/\(id)/zonefile", accept: "text/plain"))
        }
    }
}
