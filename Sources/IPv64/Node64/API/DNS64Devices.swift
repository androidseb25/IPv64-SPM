import Foundation

extension Node64.DNS64 {
    /// Devices seen by the resolver.
    public var devices: Devices { Devices(client: client) }

    /// Endpoints for devices.
    public struct Devices: Sendable {
        let client: Node64

        /// Lists the devices of the last 24 hours (name from the router, MAC from the neighbor table, group).
        ///
        /// Fails with 503 when the DNS service is not running.
        ///
        /// `GET /dns64/devices`
        public func list() async throws -> [Node64.DNS64Device] {
            try await client.send(Request(.get, "/dns64/devices"))
        }

        /// Lists the device names of the zones with their current addresses.
        ///
        /// `GET /dns64/device-names`
        public func names() async throws -> [Node64.DNS64DeviceName] {
            try await client.send(Request(.get, "/dns64/device-names"))
        }
    }
}
