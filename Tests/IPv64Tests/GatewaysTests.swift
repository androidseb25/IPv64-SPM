import Foundation
import Testing
@testable import IPv64

@Suite("Gateways")
struct GatewaysTests {
    static let gatewayJSON = """
    {"id":"GW1","name":"Gateway Frankfurt","state":"ready","disabled":false,"traffic_limited":false,
     "server":{"name":"VPN-FSN-1","hostname":"vpn1.ipv64.net","location":"Falkenstein"},"listen_port":51820,
     "ipv4":"10.7.0.1/24","ipv6":"fd64::1/64","public_key":"HIgo=","ospf":{"area_id":"0.0.0.0","ospf_version":2,"cost":10},
     "traffic_bytes":{"in":1024,"out":2048},"created_at":"2026-10-10T12:00:00+02:00",
     "peers":[{"id":"P1","name":"Laptop","state":"ready"}]}
    """

    @Test("GET /gateways/{token} decodes gateway with peers")
    func get() async throws {
        let transport = MockTransport(json: "{\"data\":\(Self.gatewayJSON)}")
        let gateway = try await IPv64.mock(transport).gateways.get("GW1")

        #expect(gateway.listenPort == 51820)
        #expect(gateway.ospf?.areaID == "0.0.0.0")
        #expect(gateway.peers?.first?.name == "Laptop")
        #expect(gateway.createdAt == Date(timeIntervalSince1970: 1_791_626_400))
        #expect(transport.lastRequest?.relativePath == "/gateways/GW1")
    }

    @Test("PATCH /gateways/{token} sends only provided fields, empty string removes an address")
    func update() async throws {
        let transport = MockTransport(json: "{\"data\":\(Self.gatewayJSON)}")
        _ = try await IPv64.mock(transport).gateways.update("GW1", name: "Neu", ipv6: "")

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.jsonBody == .object(["name": .string("Neu"), "ipv6": .string("")]))
    }

    @Test("DELETE /gateways/{token} returns the deleting gateway")
    func delete() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":{"id":"GW1","state":"deleting"}}"#)
        let gateway = try await IPv64.mock(transport).gateways.delete("GW1")
        #expect(gateway.state == .deleting)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("rotate-keys and reset-traffic use POST without body")
    func actions() async throws {
        let rotate = MockTransport(status: 202, json: "{\"data\":\(Self.gatewayJSON)}")
        _ = try await IPv64.mock(rotate).gateways.rotateKeys("GW1")
        #expect(rotate.lastRequest?.httpMethod == "POST")
        #expect(rotate.lastRequest?.relativePath == "/gateways/GW1/rotate-keys")

        let reset = MockTransport(json: "{\"data\":\(Self.gatewayJSON)}")
        _ = try await IPv64.mock(reset).gateways.resetTraffic("GW1")
        #expect(reset.lastRequest?.relativePath == "/gateways/GW1/reset-traffic")
    }

    @Test("OSPF: PUT with settings, DELETE to disable")
    func ospf() async throws {
        let put = MockTransport(status: 202, json: "{\"data\":\(Self.gatewayJSON)}")
        _ = try await IPv64.mock(put).gateways.enableOSPF("GW1", areaID: "0.0.0.0", version: 2, cost: 10)
        #expect(put.lastRequest?.httpMethod == "PUT")
        #expect(put.lastRequest?.relativePath == "/gateways/GW1/ospf")
        #expect(put.lastRequest?.jsonBody == .object([
            "area_id": .string("0.0.0.0"), "version": .number(2), "cost": .number(10),
        ]))

        let delete = MockTransport(status: 202, json: "{\"data\":\(Self.gatewayJSON)}")
        _ = try await IPv64.mock(delete).gateways.disableOSPF("GW1")
        #expect(delete.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Port forwards: decode, create, toggle, delete")
    func portForwards() async throws {
        let json = #"{"id":9,"name":"Webserver","destination":"10.7.0.2","target_port":443,"protocol":"tcp","public_port":30443,"public_ip":"server","disabled":false,"state":"ready"}"#
        let list = MockTransport(json: "{\"data\":[\(json)]}")
        let forwards = try await IPv64.mock(list).gateways.portForwards.list(gateway: "GW1")
        let forward = try #require(forwards.first)
        #expect(forward.publicPort == 30443)
        #expect(forward.protocol == .tcp)
        #expect(forward.publicIP == .server)

        let create = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(create).gateways.portForwards.create(
            gateway: "GW1", destination: "10.7.0.2", targetPort: 443, protocol: .tcp, name: "Webserver"
        )
        #expect(create.lastRequest?.relativePath == "/gateways/GW1/port-forwards")
        #expect(create.lastRequest?.jsonBody == .object([
            "destination": .string("10.7.0.2"), "target_port": .number(443),
            "protocol": .string("tcp"), "name": .string("Webserver"),
        ]))

        let toggle = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(toggle).gateways.portForwards.setDisabled(9, gateway: "GW1", disabled: true)
        #expect(toggle.lastRequest?.relativePath == "/gateways/GW1/port-forwards/9")

        let delete = MockTransport(status: 202, json: #"{"data":{"id":9,"state":"deleting"}}"#)
        let result = try await IPv64.mock(delete).gateways.portForwards.delete(9, gateway: "GW1")
        #expect(result.state == .deleting)
    }

    @Test("Peers of a gateway: list and create")
    func peers() async throws {
        let json = #"{"id":"P1","name":"Laptop","state":"applying"}"#
        let list = MockTransport(json: "{\"data\":[\(json)]}")
        let peers = try await IPv64.mock(list).gateways.peers.list(gateway: "GW1")
        #expect(peers.count == 1)
        #expect(list.lastRequest?.relativePath == "/gateways/GW1/peers")

        let create = MockTransport(status: 202, json: "{\"data\":\(json)}")
        let peer = try await IPv64.mock(create).gateways.peers.create(gateway: "GW1", name: "Laptop")
        #expect(peer.state == .applying)
        #expect(create.lastRequest?.jsonBody == .object(["name": .string("Laptop")]))
    }

    @Test("409 gateway_busy exposes retry_after")
    func gatewayBusy() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"https://ipv64.net/api/v2/errors#gateway_busy","title":"Conflict","status":409,
         "detail":"The gateway is being set up.","code":"gateway_busy","retry_after":7}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            _ = try await IPv64.mock(transport).gateways.peers.create(gateway: "GW1", name: "Laptop")
        }
        #expect(error?.code == "gateway_busy")
        #expect(error?.statusCode == 409)
        guard case .api(let problem)? = error else {
            Issue.record("Expected an API problem")
            return
        }
        #expect(problem.retryAfter == 7)
    }
}
