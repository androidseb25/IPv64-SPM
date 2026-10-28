import Foundation
import Testing
@testable import IPv64

@Suite("Node64 PROXY64 hosts and streams")
struct Node64Proxy64HostsTests {
    static let hostJSON = """
    {"id":3,"kind":"proxy","names":["a.example.com","*.example.com"],"enabled":true,"scheme":"https",
     "target_host":"10.0.0.5","target_port":8443,"websockets":true,"block_exploits":true,"cache_assets":false,
     "cert_id":-1,"force_ssl":true,"http2":true,"http3":false,"hsts":true,"hsts_subdomains":false,"min_tls":"1.3",
     "verify_target":false,"created_at":"2026-10-27T10:00:00Z","updated_at":"2026-10-27T11:00:00Z",
     "reach":{"state":"slow","ms":900,"checked_at":"2026-10-27T11:00:00Z","since":"2026-10-27T10:30:00Z"},
     "stats":{"requests":10,"errors":1,"blocked":2},
     "certificate":{"state":"soon","name":"example.com","days_left":5},
     "route_error":"","redirect_target":"b.example.com/x","redirect_scheme":"auto","redirect_code":308,"preserve_path":true,
     "access_list_id":1,
     "locations":[{"path":"/api","scheme":"http","target_host":"10.0.0.6","target_port":80,"forward_path":"/","websockets":false,"access_list_id":0}],
     "advanced":{"request_headers":[{"name":"X-A","value":"1"}],"host_header":"target","timeout_seconds":30,"max_body_mb":10,
       "geo_mode":"block","geo_countries":["RU"],"ai_bots":true,"no_limits":false},
     "dns_records":[{"name":"a.example.com","result":"created"},{"name":"b","result":"future_value"}],
     "healthchecks":[{"token":"hc1","name":"t","type":"http","state":"up","paused":false,"local":true,"host_only":false,"last_check":"2026-10-27T11:00:00Z"}],
     "status_page_id":0}
    """

    @Test("ProxyHost decodes every group of fields")
    func decodeHost() throws {
        let host = try JSONDecoder.node64Test.decode(Node64.ProxyHost.self, from: Data(Self.hostJSON.utf8))

        #expect(host.id == 3)
        #expect(host.kind == .proxy)
        #expect(host.names?.count == 2)
        #expect(host.scheme == .https)
        #expect(host.minTLS == .tls13)
        #expect(host.certID == -1)
        #expect(host.reach?.state == .slow)
        #expect(host.stats?.blocked == 2)
        #expect(host.certificate?.state == .soon)
        #expect(host.certificate?.daysLeft == 5)
        #expect(host.redirectScheme == .auto)
        #expect(host.redirectCode == 308)
        #expect(host.locations?.first?.forwardPath == "/")
        #expect(host.advanced?.geoMode == .block)
        #expect(host.advanced?.requestHeaders?.first?.name == "X-A")
        #expect(host.advanced?.aiBots == true)
        #expect(host.dnsRecords?.last?.result == Node64.ProxyHostDNSRecordResult(rawValue: "future_value"))
        #expect(host.healthchecks?.first?.hostOnly == false)
        #expect(host.healthchecks?.first?.lastCheck != nil)
    }

    @Test("Hosts list filters by kind")
    func listHosts() async throws {
        let transport = MockTransport(json: "[\(Self.hostJSON)]")
        let hosts = try await Node64.mock(transport).proxy64.hosts.list(kind: .redirect)

        #expect(hosts.count == 1)
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/hosts?kind=redirect")
    }

    @Test("Creating a host encodes snake_case keys and nested requests")
    func createHost() async throws {
        let transport = MockTransport(status: 201, json: Self.hostJSON)
        let input = Node64.ProxyHostInput(
            kind: .proxy,
            names: ["a.example.com"],
            scheme: .http,
            targetHost: "10.0.0.5",
            targetPort: 8080,
            forceSSL: true,
            minTLS: .tls12,
            requestCertificate: .init(source: .http, staging: true),
            createDNSRecord: .init(type: .cname, content: "edge.example.com"),
            statusPageID: 4
        )
        let host = try await Node64.mock(transport).proxy64.hosts.create(input)

        #expect(host.id == 3)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.nodeRelativePath == "/cdn64/hosts")
        #expect(request.jsonBody == .object([
            "kind": .string("proxy"),
            "names": .array([.string("a.example.com")]),
            "scheme": .string("http"),
            "target_host": .string("10.0.0.5"),
            "target_port": .number(8080),
            "force_ssl": .bool(true),
            "min_tls": .string("1.2"),
            "request_certificate": .object(["source": .string("http"), "staging": .bool(true)]),
            "create_dns_record": .object(["type": .string("CNAME"), "content": .string("edge.example.com")]),
            "status_page_id": .number(4),
        ]))
    }

    @Test("Host update, enable, disable and healthcheck use the right paths")
    func hostOperations() async throws {
        let transport = MockTransport(json: Self.hostJSON)
        let hosts = Node64.mock(transport).proxy64.hosts

        _ = try await hosts.get(3)
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/hosts/3")
        _ = try await hosts.update(3, .init(enabled: false))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["enabled": .bool(false)]))
        _ = try await hosts.enable(3)
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/hosts/3/enable")
        _ = try await hosts.disable(3)
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/hosts/3/disable")

        let checkTransport = MockTransport(status: 201, json: #"{"token":"hc9"}"#)
        let check = try await Node64.mock(checkTransport).proxy64.hosts.createHealthcheck(3)
        #expect(check.token == "hc9")
        #expect(checkTransport.lastRequest?.nodeRelativePath == "/cdn64/hosts/3/healthcheck")
    }

    @Test("Deleting a host returns without content, unknown hosts are 404 errors")
    func deleteHost() async throws {
        let transport = MockTransport(status: 204, body: Data())
        try await Node64.mock(transport).proxy64.hosts.delete(3)
        #expect(transport.lastRequest?.httpMethod == "DELETE")

        let missing = MockTransport(status: 404, json: #"{"error":"not found"}"#, headers: ["Content-Type": "application/json"])
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(missing).proxy64.hosts.get(99)
        }
        #expect(error?.statusCode == 404)
    }

    @Test("ProxyStream decodes and the input encodes")
    func streams() async throws {
        let json = """
        {"id":5,"name":"ssh","enabled":true,"listen_port":2222,"tcp":true,"udp":false,"target_host":"10.0.0.7",
         "target_port":22,"tls_cert_id":0,"created_at":"2026-10-27T10:00:00Z","updated_at":"2026-10-27T10:00:00Z",
         "running":true,"reach":{"state":"up"},"listen_errors":{"udp":"disabled"},
         "stats":{"connections":10,"active":1,"bytes_in":100,"bytes_out":200},"cert_name":"",
         "geo_mode":"allow","geo_countries":["DE","AT"]}
        """
        let transport = MockTransport(status: 201, json: json)
        let streams = Node64.mock(transport).proxy64.streams

        let stream = try await streams.create(.init(name: "ssh", listenPort: 2222, tcp: true, udp: false, geoMode: .allow, geoCountries: ["DE", "AT"]))

        #expect(stream.id == 5)
        #expect(stream.listenPort == 2222)
        #expect(stream.stats?.bytesOut == 200)
        #expect(stream.listenErrors?["udp"] == "disabled")
        #expect(stream.geoMode == .allow)
        #expect(stream.reach == .object(["state": .string("up")]))
        #expect(transport.lastRequest?.jsonBody == .object([
            "name": .string("ssh"), "listen_port": .number(2222), "tcp": .bool(true), "udp": .bool(false),
            "geo_mode": .string("allow"), "geo_countries": .array([.string("DE"), .string("AT")]),
        ]))

        _ = try await streams.enable(5)
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/streams/5/enable")
        _ = try await streams.update(5, .init(targetPort: 2200))
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/streams/5")
        #expect(transport.lastRequest?.httpMethod == "PUT")
    }
}

extension JSONDecoder {
    /// Decoder with the node's ISO 8601 date handling for model-only tests.
    fileprivate static var node64Test: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
