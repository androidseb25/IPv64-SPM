import Foundation

extension Node64.Ports {
    /// Ports used by all parts of the node, with overlaps, plus the state of the shared entry point.
    ///
    /// `GET /ports`
    public func list() async throws -> Node64.PortOverview {
        try await client.send(Request(.get, "/ports"))
    }

    /// Checks whether a port is free on the host.
    ///
    /// - Parameters:
    ///   - port: Port number.
    ///   - transport: `tcp` or `udp` (sent as `proto`).
    ///   - bind: Address to test; defaults to all addresses.
    ///
    /// An invalid `transport` or `port` fails with status 422.
    ///
    /// `GET /ports/probe`
    public func probe(port: Int, transport: Node64.PortProtocol, bind: String? = nil) async throws -> Node64.PortProbeResult {
        try await client.send(Request(.get, "/ports/probe", query: [
            QueryItem("proto", transport),
            QueryItem("port", port),
            QueryItem("bind", bind),
        ]))
    }

    /// Shared entry point (edge): settings, listeners and Node64 interface name.
    public var edge: Edge { Edge(client: client) }

    /// Endpoints of the shared entry point (*Gemeinsamer Eingang*).
    public struct Edge: Sendable {
        let client: Node64

        /// Shared entry point: settings, open ports and registered names.
        ///
        /// `GET /edge`
        public func get() async throws -> Node64.EdgeStatus {
            try await client.send(Request(.get, "/edge"))
        }

        /// Changes the settings of the entry point. Fields left `nil` are not sent and stay unchanged.
        ///
        /// Open ports are closed briefly and reopened. Ports open only while a module needs them.
        /// An invalid or duplicate port fails with status 422.
        ///
        /// `PUT /edge`
        public func update(_ config: Node64.EdgeConfig) async throws -> Node64.EdgeStatus {
            try await client.send(Request(.put, "/edge", body: .json(config)))
        }

        /// Node64 interface under its own name behind the shared entry point.
        ///
        /// `GET /edge/ui`
        public func ui() async throws -> Node64.EdgeUI {
            try await client.send(Request(.get, "/edge/ui"))
        }

        /// Changes name, exposure and certificate of the interface (no restart).
        ///
        /// - Parameters:
        ///   - name: Name at the edge; `""` switches it off.
        ///   - isPublic: Also reachable from the internet (default: own network only).
        ///   - cert: `auto`, `self` or an ID from `/certs`.
        ///
        /// Fields left `nil` are not sent; the spec does not state whether the node keeps them.
        /// A name that is invalid or already used by a host fails with status 422.
        /// The response documents only `name` and `public`.
        ///
        /// `PUT /edge/ui`
        public func updateUI(name: String? = nil, isPublic: Bool? = nil, cert: String? = nil) async throws -> Node64.EdgeUI {
            try await client.send(Request(.put, "/edge/ui", body: .json(UIBody(name: name, isPublic: isPublic, cert: cert))))
        }

        private struct UIBody: Encodable, Sendable {
            let name: String?
            let isPublic: Bool?
            let cert: String?

            enum CodingKeys: String, CodingKey {
                case name
                case isPublic = "public"
                case cert
            }
        }
    }
}
