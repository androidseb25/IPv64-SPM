import Foundation

extension IPv64 {
    /// Cloud Routers: WireGuard routers with gateways, routes, firewall rules and public IPs.
    ///
    /// Most changes are applied asynchronously by a background service and answer
    /// `202 Accepted` with the new state; poll until `state == ready`. While a
    /// gateway is being set up, further changes fail with `409 gateway_busy` and
    /// a `retry_after` hint (see ``IPv64Problem``).
    public var cloudRouters: CloudRouters { CloudRouters(client: self) }

    /// Endpoints of the *Cloud Router* area.
    public struct CloudRouters: Sendable {
        let client: IPv64

        /// Lists all Cloud Routers.
        ///
        /// `GET /cloud-routers`
        public func list() async throws -> [CloudRouter] {
            try await client.send(Request(.get, "/cloud-routers"))
        }

        /// Creates a router and its first gateway.
        ///
        /// Asynchronous: answers `202 Accepted`; the new router is ready once its gateways have `state == ready`.
        ///
        /// `POST /cloud-routers`
        /// - Parameter name: Name of the router, e.g. `Home Lab`.
        public func create(name: String? = nil) async throws -> CloudRouter {
            try await client.send(Request(.post, "/cloud-routers", body: .json(NameBody(name: name))))
        }

        /// Returns a Cloud Router with its gateways, peers and IPs.
        ///
        /// `GET /cloud-routers/{token}`
        public func get(_ router: String) async throws -> CloudRouter {
            try await client.send(Request(.get, "/cloud-routers/\(router)"))
        }

        /// Renames a router.
        ///
        /// `PATCH /cloud-routers/{token}`
        public func rename(_ router: String, to name: String) async throws -> CloudRouter {
            try await client.send(Request(.patch, "/cloud-routers/\(router)", body: .json(NameBody(name: name))))
        }

        /// Creates another gateway on the router.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /cloud-routers/{token}/gateways`
        public func createGateway(router: String, name: String? = nil) async throws -> Gateway {
            try await client.send(Request(.post, "/cloud-routers/\(router)/gateways", body: .json(NameBody(name: name))))
        }

        /// Static routes of the router.
        public var routes: Routes { Routes(client: client) }
        /// Firewall rules of the router.
        public var firewall: Firewall { Firewall(client: client) }
        /// Public IPs of the router.
        public var publicIPs: PublicIPs { PublicIPs(client: client) }

        private struct NameBody: Encodable, Sendable {
            let name: String?
        }
    }
}

private struct DisabledBody: Encodable, Sendable {
    let disabled: Bool
}

extension IPv64.CloudRouters {
    /// Static routes of a Cloud Router.
    public struct Routes: Sendable {
        let client: IPv64

        /// Lists the routes of a router.
        ///
        /// `GET /cloud-routers/{token}/routes`
        public func list(router: String) async throws -> [Route] {
            try await client.send(Request(.get, "/cloud-routers/\(router)/routes"))
        }

        /// Creates a static route to a network behind a peer.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /cloud-routers/{token}/routes`
        /// - Parameters:
        ///   - router: Router token.
        ///   - destination: Destination network in CIDR, e.g. `192.168.50.0/24`.
        ///   - gateway: Next hop, same address family as the destination, e.g. `10.7.0.2`.
        ///   - peer: ID of the peer behind which the network lives.
        ///   - distance: Administrative distance.
        public func create(
            router: String,
            destination: String,
            gateway: String,
            peer: String,
            distance: Int? = nil
        ) async throws -> Route {
            let body = Body(destination: destination, gateway: gateway, peer: peer, distance: distance)
            return try await client.send(Request(.post, "/cloud-routers/\(router)/routes", body: .json(body)))
        }

        /// Enables or disables a route.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `PATCH /cloud-routers/{token}/routes/{id}`
        public func setDisabled(_ id: Int, router: String, disabled: Bool) async throws -> Route {
            try await client.send(Request(.patch, "/cloud-routers/\(router)/routes/\(id)", body: .json(DisabledBody(disabled: disabled))))
        }

        /// Deletes a route. System routes cannot be deleted.
        ///
        /// Asynchronous: answers `202 Accepted` with state `deleting`.
        ///
        /// `DELETE /cloud-routers/{token}/routes/{id}`
        public func delete(_ id: Int, router: String) async throws -> CloudRouterDeletion {
            try await client.send(Request(.delete, "/cloud-routers/\(router)/routes/\(id)"))
        }

        private struct Body: Encodable, Sendable {
            let destination: String
            let gateway: String
            let peer: String
            let distance: Int?
        }
    }

    /// Firewall rules of a Cloud Router.
    public struct Firewall: Sendable {
        let client: IPv64

        /// Lists the firewall rules of a router.
        ///
        /// `GET /cloud-routers/{token}/firewall`
        public func list(router: String) async throws -> [FirewallRule] {
            try await client.send(Request(.get, "/cloud-routers/\(router)/firewall"))
        }

        /// Creates a firewall rule.
        ///
        /// `source` and `destination` must belong to the same address family and at least one of them is required.
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /cloud-routers/{token}/firewall`
        /// - Parameters:
        ///   - router: Router token.
        ///   - chain: Chain (`forward`, `input`, `output`).
        ///   - action: Action (`accept`, `drop`).
        ///   - source: Source as IP or CIDR, e.g. `10.7.0.0/24`.
        ///   - destination: Destination as IP or CIDR, e.g. `192.168.50.10`.
        public func create(
            router: String,
            chain: FirewallRuleChain,
            action: FirewallRuleAction,
            source: String? = nil,
            destination: String? = nil
        ) async throws -> FirewallRule {
            let body = Body(chain: chain, action: action, source: source, destination: destination)
            return try await client.send(Request(.post, "/cloud-routers/\(router)/firewall", body: .json(body)))
        }

        /// Enables or disables a rule.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `PATCH /cloud-routers/{token}/firewall/{id}`
        public func setDisabled(_ id: Int, router: String, disabled: Bool) async throws -> FirewallRule {
            try await client.send(Request(.patch, "/cloud-routers/\(router)/firewall/\(id)", body: .json(DisabledBody(disabled: disabled))))
        }

        /// Deletes a rule.
        ///
        /// Asynchronous: answers `202 Accepted` with state `deleting`.
        ///
        /// `DELETE /cloud-routers/{token}/firewall/{id}`
        public func delete(_ id: Int, router: String) async throws -> CloudRouterDeletion {
            try await client.send(Request(.delete, "/cloud-routers/\(router)/firewall/\(id)"))
        }

        private struct Body: Encodable, Sendable {
            let chain: FirewallRuleChain
            let action: FirewallRuleAction
            let source: String?
            let destination: String?
        }
    }

    /// Public IPs of a Cloud Router.
    public struct PublicIPs: Sendable {
        let client: IPv64

        /// Lists the public IPs of a router.
        ///
        /// `GET /cloud-routers/{token}/public-ips`
        public func list(router: String) async throws -> [PublicIP] {
            try await client.send(Request(.get, "/cloud-routers/\(router)/public-ips"))
        }

        /// Creates a public IPv6 address. At most one IPv6 per router; the address is picked randomly from the VPN server's network.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `POST /cloud-routers/{token}/public-ips`
        public func create(router: String) async throws -> PublicIP {
            try await client.send(Request(.post, "/cloud-routers/\(router)/public-ips"))
        }

        /// Enables or disables a public IP.
        ///
        /// Asynchronous: answers `202 Accepted`; wait for `state == ready`.
        ///
        /// `PATCH /cloud-routers/{token}/public-ips/{id}`
        public func setDisabled(_ id: Int, router: String, disabled: Bool) async throws -> PublicIP {
            try await client.send(Request(.patch, "/cloud-routers/\(router)/public-ips/\(id)", body: .json(DisabledBody(disabled: disabled))))
        }

        /// Deletes a public IP. Port forwards on this IP are set up again.
        ///
        /// Asynchronous: answers `202 Accepted` with state `deleting`.
        ///
        /// `DELETE /cloud-routers/{token}/public-ips/{id}`
        public func delete(_ id: Int, router: String) async throws -> CloudRouterDeletion {
            try await client.send(Request(.delete, "/cloud-routers/\(router)/public-ips/\(id)"))
        }
    }
}
