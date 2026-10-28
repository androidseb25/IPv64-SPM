import Foundation
import Testing
@testable import IPv64

@Suite("Cloud Routers")
struct CloudRoutersTests {
    static let routerJSON = """
    {"id":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","name":"Home Lab","vrf":"vrf522a","traffic_limited":false,
     "gateways":[{"id":"GW1","name":"Gateway Frankfurt","state":"ready","disabled":false,"traffic_limited":false,
       "server":{"name":"VPN-FSN-1","hostname":"vpn1.ipv64.net","location":"Falkenstein"},"listen_port":51820,
       "ipv4":"10.7.0.1/24","ipv6":null,"public_key":"HIgo=","ospf":{"area_id":"0.0.0.0","ospf_version":2,"cost":10},
       "traffic_bytes":{"in":1024,"out":2048},"created_at":"2026-10-10T12:00:00+02:00","peers":[]}],
     "public_ips":[{"id":5,"ip":"2001:db8:64::1a2b:3c4d","type":"ipv6","disabled":false,"state":"ready","created_at":"2026-10-10T12:00:00+02:00"}]}
    """

    @Test("GET /cloud-routers decodes routers with gateways and public IPs")
    func list() async throws {
        let transport = MockTransport(json: "{\"data\":[\(Self.routerJSON)]}")
        let routers = try await IPv64.mock(transport).cloudRouters.list()

        let router = try #require(routers.first)
        #expect(router.vrf == "vrf522a")
        let gateway = try #require(router.gateways?.first)
        #expect(gateway.server?.hostname == "vpn1.ipv64.net")
        #expect(gateway.ospf?.version == 2)
        #expect(gateway.trafficBytes?.out == 2048)
        #expect(gateway.ipv6 == nil)
        #expect(router.publicIPs?.first?.type == .ipv6)
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    }

    @Test("POST /cloud-routers sends the name and accepts 202")
    func create() async throws {
        let transport = MockTransport(status: 202, json: "{\"data\":\(Self.routerJSON)}")
        let router = try await IPv64.mock(transport).cloudRouters.create(name: "Home Lab")

        #expect(router.id == "Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/cloud-routers")
        #expect(request.jsonBody == .object(["name": .string("Home Lab")]))
    }

    @Test("PATCH /cloud-routers/{token} renames")
    func rename() async throws {
        let transport = MockTransport(json: "{\"data\":\(Self.routerJSON)}")
        _ = try await IPv64.mock(transport).cloudRouters.rename("tok/en", to: "Buero")

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.relativePath == "/cloud-routers/tok%2Fen")
        #expect(request.jsonBody == .object(["name": .string("Buero")]))
    }

    @Test("POST /cloud-routers/{token}/gateways creates a gateway")
    func createGateway() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":{"id":"GW2","name":"Gateway 2","state":"creating"}}"#)
        let gateway = try await IPv64.mock(transport).cloudRouters.createGateway(router: "R1", name: "Gateway 2")

        #expect(gateway.state == .creating)
        #expect(transport.lastRequest?.relativePath == "/cloud-routers/R1/gateways")
    }

    @Test("Routes: list decodes and create sends all fields")
    func routes() async throws {
        let json = #"{"id":21,"destination":"192.168.50.0/24","gateway":"10.7.0.2","distance":1,"peer":null,"system":false,"disabled":false,"state":"ready"}"#
        let list = MockTransport(json: "{\"data\":[\(json)]}")
        let routes = try await IPv64.mock(list).cloudRouters.routes.list(router: "R1")
        #expect(routes.first?.destination == "192.168.50.0/24")
        #expect(routes.first?.peer == nil)
        #expect(list.lastRequest?.relativePath == "/cloud-routers/R1/routes")

        let create = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(create).cloudRouters.routes.create(
            router: "R1", destination: "192.168.50.0/24", gateway: "10.7.0.2", peer: "P1", distance: 1
        )
        #expect(create.lastRequest?.jsonBody == .object([
            "destination": .string("192.168.50.0/24"),
            "gateway": .string("10.7.0.2"),
            "peer": .string("P1"),
            "distance": .number(1),
        ]))
    }

    @Test("Route toggle and delete")
    func routeToggleDelete() async throws {
        let toggle = MockTransport(status: 202, json: #"{"data":{"id":21,"disabled":true,"state":"applying"}}"#)
        let route = try await IPv64.mock(toggle).cloudRouters.routes.setDisabled(21, router: "R1", disabled: true)
        #expect(route.state == .applying)
        #expect(toggle.lastRequest?.httpMethod == "PATCH")
        #expect(toggle.lastRequest?.relativePath == "/cloud-routers/R1/routes/21")
        #expect(toggle.lastRequest?.jsonBody == .object(["disabled": .bool(true)]))

        let delete = MockTransport(status: 202, json: #"{"data":{"id":21,"state":"deleting"}}"#)
        let result = try await IPv64.mock(delete).cloudRouters.routes.delete(21, router: "R1")
        #expect(result.state == .deleting)
        #expect(delete.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Firewall: decode, create (omits nil fields), toggle, delete")
    func firewall() async throws {
        let json = #"{"id":4,"chain":"forward","action":"drop","family":"ipv4","source":"10.7.0.0/24","destination":null,"disabled":false,"state":"ready"}"#
        let list = MockTransport(json: "{\"data\":[\(json)]}")
        let rules = try await IPv64.mock(list).cloudRouters.firewall.list(router: "R1")
        #expect(rules.first?.chain == .forward)
        #expect(rules.first?.action == .drop)
        #expect(rules.first?.family == .ipv4)
        #expect(rules.first?.destination == nil)

        let create = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(create).cloudRouters.firewall.create(
            router: "R1", chain: .forward, action: .drop, source: "10.7.0.0/24"
        )
        #expect(create.lastRequest?.relativePath == "/cloud-routers/R1/firewall")
        #expect(create.lastRequest?.jsonBody == .object([
            "chain": .string("forward"), "action": .string("drop"), "source": .string("10.7.0.0/24"),
        ]))

        let toggle = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(toggle).cloudRouters.firewall.setDisabled(4, router: "R1", disabled: false)
        #expect(toggle.lastRequest?.relativePath == "/cloud-routers/R1/firewall/4")

        let delete = MockTransport(status: 202, json: #"{"data":{"id":4,"state":"deleting"}}"#)
        let result = try await IPv64.mock(delete).cloudRouters.firewall.delete(4, router: "R1")
        #expect(result.id == 4)
    }

    @Test("Public IPs: list, create, toggle, delete")
    func publicIPs() async throws {
        let json = #"{"id":5,"ip":"2001:db8:64::1a2b:3c4d","type":"ipv6","disabled":false,"state":"ready","created_at":"2026-10-10T12:00:00+02:00"}"#
        let list = MockTransport(json: "{\"data\":[\(json)]}")
        let ips = try await IPv64.mock(list).cloudRouters.publicIPs.list(router: "R1")
        #expect(ips.first?.createdAt == Date(timeIntervalSince1970: 1_791_626_400))

        let create = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(create).cloudRouters.publicIPs.create(router: "R1")
        #expect(create.lastRequest?.httpMethod == "POST")
        #expect(create.lastRequest?.httpBody == nil)
        #expect(create.lastRequest?.relativePath == "/cloud-routers/R1/public-ips")

        let toggle = MockTransport(status: 202, json: "{\"data\":\(json)}")
        _ = try await IPv64.mock(toggle).cloudRouters.publicIPs.setDisabled(5, router: "R1", disabled: true)
        #expect(toggle.lastRequest?.relativePath == "/cloud-routers/R1/public-ips/5")

        let delete = MockTransport(status: 202, json: #"{"data":{"id":5,"state":"deleting"}}"#)
        _ = try await IPv64.mock(delete).cloudRouters.publicIPs.delete(5, router: "R1")
        #expect(delete.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Errors are thrown as IPv64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 404, json: """
        {"type":"https://ipv64.net/api/v2/errors#not_found","title":"Not Found","status":404,"detail":"Router not found.","code":"not_found"}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            _ = try await IPv64.mock(transport).cloudRouters.get("nope")
        }
        #expect(error?.code == "not_found")
        #expect(error?.statusCode == 404)
    }
}
