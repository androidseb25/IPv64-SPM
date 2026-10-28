import Foundation
import Testing
@testable import IPv64

@Suite("CDN")
struct CDNTests {
    static let domainJSON = """
    {"id":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","domain":"beispiel.ipv64.de","domain_id":17597,"active":true,
    "pending":["config_deploy","certificate"],"dns_records_enabled":true,
    "server":{"name":"CDN-FSN-1","hostname":"cdn1.ipv64.net","ipv4":"203.0.113.1","ipv6":"2001:db8::1"},
    "proxy":{"state":"on","frontend":"https_redirect","backend":{"scheme":"http","port":80},"websocket":false,
    "certificate":"letsencrypt","caching":{"enabled":false,"time_minutes":60,"size_mb":100},
    "access_list":{"enabled":false,"mode":"denylist"}},
    "portmapper":{"state":"off"},"traffic_mb":{"in":120.5,"out":830.2},"created_at":"2026-10-10T12:00:00+02:00"}
    """

    static let mappingJSON = """
    {"id":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","name":"Minecraft","listen_port":51234,"transport":"tcp",
    "target_port":25565,"record":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","fqdn":"mc.beispiel.ipv64.de"}
    """

    static let token = "Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z"

    @Test("CDNDomain decodes the spec example")
    func decodeDomain() throws {
        let domain = try IPv64Coding.makeDecoder().decode(CDNDomain.self, from: Data(Self.domainJSON.utf8))
        #expect(domain.domainID == 17597)
        #expect(domain.pending == [.configDeploy, .certificate])
        #expect(domain.server?.hostname == "cdn1.ipv64.net")
        #expect(domain.proxy?.state == .on)
        #expect(domain.proxy?.frontend == .httpsRedirect)
        #expect(domain.proxy?.backend?.scheme == .http)
        #expect(domain.proxy?.caching?.timeMinutes == 60)
        #expect(domain.proxy?.accessList?.mode == .denylist)
        #expect(domain.portmapper?.state == .off)
        #expect(domain.trafficMB?.incoming == 120.5)
        #expect(domain.createdAt != nil)
    }

    @Test("CDNDomainDetail decodes mappings and tolerates null server")
    func decodeDetail() throws {
        let json = """
        {"id":"x","server":null,"mappings":[\(Self.mappingJSON)]}
        """
        let detail = try IPv64Coding.makeDecoder().decode(CDNDomainDetail.self, from: Data(json.utf8))
        #expect(detail.server == nil)
        let mapping = try #require(detail.mappings?.first)
        #expect(mapping.transport == .tcp)
        #expect(mapping.listenPort == 51234)
        #expect(mapping.fqdn == "mc.beispiel.ipv64.de")
    }

    @Test("AccessListEntry decodes")
    func decodeEntry() throws {
        let entry = try IPv64Coding.makeDecoder().decode(
            AccessListEntry.self, from: Data(#"{"id":7,"address":"198.51.100.0/24"}"#.utf8))
        #expect(entry.id == 7)
        #expect(entry.address == "198.51.100.0/24")
    }

    @Test("GET /cdn lists domains")
    func list() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.domainJSON)]}"#)
        let domains = try await IPv64.mock(transport).cdn.list()
        #expect(domains.count == 1)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.relativePath == "/cdn")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    }

    @Test("POST /cdn sends the domain")
    func add() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.domainJSON)}"#)
        _ = try await IPv64.mock(transport).cdn.add(domain: "beispiel.ipv64.de")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.jsonBody == .object(["domain": .string("beispiel.ipv64.de")]))
    }

    @Test("PATCH /cdn/{token} sends only provided fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.domainJSON)}"#)
        _ = try await IPv64.mock(transport).cdn.update(
            Self.token,
            frontend: .httpsRedirect,
            backendPort: 8080,
            caching: .init(enabled: true, timeMinutes: 60, sizeMB: 100)
        )
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.relativePath == "/cdn/\(Self.token)")
        #expect(request.jsonBody == .object([
            "frontend": .string("https_redirect"),
            "backend_port": .number(8080),
            "caching": .object(["enabled": .bool(true), "time_minutes": .number(60), "size_mb": .number(100)]),
        ]))
    }

    @Test("202 Accepted returns the new state with pending work")
    func accepted() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":\#(Self.domainJSON)}"#)
        let domain = try await IPv64.mock(transport).cdn.enableProxy(Self.token)
        #expect(domain.pending?.isEmpty == false)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/cdn/\(Self.token)/proxy/enable")
        #expect(request.httpBody == nil)
    }

    @Test("409 problem exposes code and retry_after")
    func conflict() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"https://ipv64.net/api/v2/errors#cdn_busy","title":"Conflict","status":409,
        "detail":"CDN is busy.","code":"cdn_busy","retry_after":15}
        """)
        do {
            _ = try await IPv64.mock(transport).cdn.redeploy(Self.token)
            Issue.record("Expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "cdn_busy")
            #expect(problem.status == 409)
            #expect(problem.retryAfter == 15)
        }
    }

    @Test("Action endpoints use the right paths")
    func actions() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":\#(Self.domainJSON)}"#)
        let cdn = IPv64.mock(transport).cdn
        _ = try await cdn.disableProxy(Self.token)
        _ = try await cdn.enablePortmapper(Self.token)
        _ = try await cdn.disablePortmapper(Self.token)
        _ = try await cdn.redeploy(Self.token)
        _ = try await cdn.resetTraffic(Self.token)
        _ = try await cdn.move(Self.token)
        _ = try await cdn.renewCertificate(Self.token)
        _ = try await cdn.delete(Self.token)
        let prefix = "/cdn/\(Self.token)"
        let sent = transport.requests.map { "\($0.httpMethod ?? "") \($0.relativePath)" }
        #expect(sent == [
            "POST \(prefix)/proxy/disable", "POST \(prefix)/portmapper/enable",
            "POST \(prefix)/portmapper/disable", "POST \(prefix)/redeploy",
            "POST \(prefix)/reset-traffic", "POST \(prefix)/move",
            "POST \(prefix)/renew-certificate", "DELETE \(prefix)",
        ])
    }

    @Test("Records: list, enable with mode, disable")
    func records() async throws {
        let record = #"{"id":4711,"type":"A","state":"cdn_proxied"}"#
        let transport = MockTransport(status: 202, json: #"{"data":\#(record)}"#)
        let records = IPv64.mock(transport).cdn.records
        let enabled = try await records.enable("4711", cdn: Self.token, mode: .otherFamilyOnly)
        #expect(enabled.state == .cdnProxied)
        var request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/cdn/\(Self.token)/records/4711/enable")
        #expect(request.jsonBody == .object(["mode": .string("other_family_only")]))

        _ = try await records.disable("4711", cdn: Self.token)
        request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/cdn/\(Self.token)/records/4711/disable")

        let listTransport = MockTransport(json: #"{"data":[\#(record)]}"#)
        let list = try await IPv64.mock(listTransport).cdn.records.list(cdn: Self.token)
        #expect(list.first?.id == 4711)
        #expect(listTransport.lastRequest?.relativePath == "/cdn/\(Self.token)/records")
    }

    @Test("Mappings: create body, list, delete returns 204")
    func mappings() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.mappingJSON)}"#)
        let mappings = IPv64.mock(transport).cdn.mappings
        let created = try await mappings.create(
            cdn: Self.token, record: "4711", targetPort: 25565, transport: .tcp, name: "Minecraft")
        #expect(created.targetPort == 25565)
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/cdn/\(Self.token)/mappings")
        #expect(request.jsonBody == .object([
            "record": .string("4711"), "target_port": .number(25565),
            "transport": .string("tcp"), "name": .string("Minecraft"),
        ]))

        let listTransport = MockTransport(json: #"{"data":[\#(Self.mappingJSON)]}"#)
        #expect(try await IPv64.mock(listTransport).cdn.mappings.list(cdn: Self.token).count == 1)

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await IPv64.mock(deleteTransport).cdn.mappings.delete("a b", cdn: Self.token)
        let deleteRequest = try #require(deleteTransport.lastRequest)
        #expect(deleteRequest.httpMethod == "DELETE")
        #expect(deleteRequest.relativePath == "/cdn/\(Self.token)/mappings/a%20b")
    }

    @Test("Access list: list, add, delete")
    func accessList() async throws {
        let entry = #"{"id":7,"address":"198.51.100.0/24"}"#
        let transport = MockTransport(status: 201, json: #"{"data":\#(entry)}"#)
        let added = try await IPv64.mock(transport).cdn.accessList.add(cdn: Self.token, address: "198.51.100.0/24")
        #expect(added.id == 7)
        #expect(transport.lastRequest?.jsonBody == .object(["address": .string("198.51.100.0/24")]))

        let listTransport = MockTransport(json: #"{"data":[\#(entry)]}"#)
        #expect(try await IPv64.mock(listTransport).cdn.accessList.list(cdn: Self.token).count == 1)
        #expect(listTransport.lastRequest?.relativePath == "/cdn/\(Self.token)/access-list")

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await IPv64.mock(deleteTransport).cdn.accessList.delete(7, cdn: Self.token)
        #expect(deleteTransport.lastRequest?.relativePath == "/cdn/\(Self.token)/access-list/7")
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
    }
}
