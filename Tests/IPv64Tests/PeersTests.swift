import Foundation
import Testing
@testable import IPv64

@Suite("Peers")
struct PeersTests {
    static let peerJSON = """
    {"id":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","name":"Laptop","state":"ready","disabled":false,"site_to_site":false,
     "ipv4":"10.7.0.2/32","ipv6":null,"dns_server":null,"endpoint":null,"endpoint_port":null,"keepalive":"00:00:25",
     "public_key":"xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=","has_preshared_key":true,
     "current_endpoint":"198.51.100.7:51820","last_handshake":null,"traffic_bytes":{"in":1024,"out":2048},
     "allowed_ips":[{"id":3,"network":"192.168.50.0/24"}]}
    """

    @Test("GET /peers/{token} decodes a peer")
    func get() async throws {
        let transport = MockTransport(json: "{\"data\":\(Self.peerJSON)}")
        let peer = try await IPv64.mock(transport).peers.get("Ab3d")

        #expect(peer.ipv4 == "10.7.0.2/32")
        #expect(peer.ipv6 == nil)
        #expect(peer.siteToSite == false)
        #expect(peer.hasPresharedKey == true)
        #expect(peer.keepalive == "00:00:25")
        #expect(peer.trafficBytes?.in == 1024)
        #expect(peer.allowedIPs?.first?.network == "192.168.50.0/24")
        #expect(transport.lastRequest?.relativePath == "/peers/Ab3d")
    }

    @Test("PATCH /peers/{token} sends only set fields and accepts 202")
    func update() async throws {
        let transport = MockTransport(status: 202, json: "{\"data\":\(Self.peerJSON)}")
        _ = try await IPv64.mock(transport).peers.update(
            "P1", PeerInput(dnsServer: "1.1.1.1", endpointPort: 51820, siteToSite: true)
        )

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.jsonBody == .object([
            "dns_server": .string("1.1.1.1"), "endpoint_port": .number(51820), "site_to_site": .bool(true),
        ]))
    }

    @Test("DELETE /peers/{token} returns the deleting peer")
    func delete() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":{"id":"P1","state":"deleting"}}"#)
        let peer = try await IPv64.mock(transport).peers.delete("P1")
        #expect(peer.state == .deleting)
    }

    @Test("GET /peers/{token}/config returns text/plain")
    func config() async throws {
        let conf = "[Interface]\nPrivateKey = abc=\nAddress = 10.7.0.2/32\n"
        let transport = MockTransport(status: 200, body: Data(conf.utf8), headers: ["Content-Type": "text/plain"])
        let text = try await IPv64.mock(transport).peers.config("P1")

        #expect(text == conf)
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/peers/P1/config")
        #expect(request.value(forHTTPHeaderField: "Accept")?.hasPrefix("text/plain") == true)
    }

    @Test("Key operations use the right method and path")
    func keys() async throws {
        let rotate = MockTransport(status: 202, json: "{\"data\":\(Self.peerJSON)}")
        _ = try await IPv64.mock(rotate).peers.rotateKeys("P1")
        #expect(rotate.lastRequest?.httpMethod == "POST")
        #expect(rotate.lastRequest?.relativePath == "/peers/P1/rotate-keys")

        let preshared = MockTransport(status: 202, json: "{\"data\":\(Self.peerJSON)}")
        _ = try await IPv64.mock(preshared).peers.rotatePresharedKey("P1")
        #expect(preshared.lastRequest?.relativePath == "/peers/P1/rotate-preshared-key")

        let set = MockTransport(status: 202, json: "{\"data\":\(Self.peerJSON)}")
        _ = try await IPv64.mock(set).peers.setKeys("P1", publicKey: "pub=", presharedKey: "psk=")
        #expect(set.lastRequest?.httpMethod == "PUT")
        #expect(set.lastRequest?.relativePath == "/peers/P1/keys")
        #expect(set.lastRequest?.jsonBody == .object([
            "public_key": .string("pub="), "preshared_key": .string("psk="),
        ]))
    }

    @Test("AllowedIPs: add returns the peer (201), remove returns 204")
    func allowedIPs() async throws {
        let add = MockTransport(status: 201, json: "{\"data\":\(Self.peerJSON)}")
        let peer = try await IPv64.mock(add).peers.addAllowedIP("P1", network: "192.168.50.0/24")
        #expect(peer.allowedIPs?.count == 1)
        #expect(add.lastRequest?.relativePath == "/peers/P1/allowed-ips")
        #expect(add.lastRequest?.jsonBody == .object(["network": .string("192.168.50.0/24")]))

        let remove = MockTransport(status: 204)
        try await IPv64.mock(remove).peers.removeAllowedIP(3, peer: "P1")
        #expect(remove.lastRequest?.httpMethod == "DELETE")
        #expect(remove.lastRequest?.relativePath == "/peers/P1/allowed-ips/3")
    }

    @Test("Errors are thrown as IPv64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 404, json: """
        {"type":"https://ipv64.net/api/v2/errors#not_found","title":"Not Found","status":404,"detail":"Peer not found.","code":"not_found"}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            _ = try await IPv64.mock(transport).peers.get("nope")
        }
        #expect(error?.code == "not_found")
    }
}
