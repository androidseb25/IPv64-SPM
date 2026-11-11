import Foundation
import Testing
@testable import IPv64

@Suite("Node64 PROXY64, ports and certificates: new endpoints")
struct Node64Proxy64NewEndpointsTests {
    static let serversJSON = """
    {"count":2,"choice":0,"max":4,"all":true,"total":4,"selectable":true,"assigned":["srv07","srv08"],
     "active":["srv07"],"sessions":3,"sessions_max":8,"replaced":{"srv07":"srv09"},"options":[0,1,2],"session_options":[1,2,3]}
    """

    @Test("Docker sync get and partial update")
    func docker() async throws {
        let transport = MockTransport(json: """
        {"enabled":true,"connected":false,"host":"unix:///var/run/docker.sock","error":"x","synced":"2026-11-01T10:00:00Z",
         "containers":[{"name":"web"}],"settings":{"enabled":true,"traefik":true,"docker_host":"","certificate":"auto"}}
        """)
        let docker = try await Node64.mock(transport).proxy64.docker()
        #expect(docker.connected == false)
        #expect(docker.synced != nil)
        #expect(docker.containers?.count == 1)
        #expect(docker.settings?.certificate == "auto")
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/docker")

        _ = try await Node64.mock(transport).proxy64.updateDocker(enabled: true, dockerHost: "tcp://proxy:2375", acceptTOS: true)
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object([
            "enabled": .bool(true), "docker_host": .string("tcp://proxy:2375"), "accept_tos": .bool(true),
        ]))
    }

    @Test("Host servers, protection and local DNS")
    func hostOps() async throws {
        let servers = MockTransport(json: Self.serversJSON)
        let got = try await Node64.mock(servers).proxy64.hosts.servers(5)
        #expect(got.sessionsMax == 8)
        #expect(got.replaced?["srv07"] == "srv09")
        #expect(got.sessionOptions == [1, 2, 3])
        #expect(servers.lastRequest?.nodeRelativePath == "/cdn64/hosts/5/servers")

        _ = try await Node64.mock(servers).proxy64.hosts.updateServers(5, count: 0, sessions: 2)
        #expect(servers.lastRequest?.httpMethod == "PUT")
        #expect(servers.lastRequest?.jsonBody == .object(["count": .number(0), "sessions": .number(2)]))

        let protection = MockTransport(json: #"{"waf":true,"ja4":"count","names":[{"id":1,"fqdn":"a.example.com","waf":true,"ja4":"block"}]}"#)
        let prot = try await Node64.mock(protection).proxy64.hosts.updateProtection(5, waf: true, ja4: .count)
        #expect(prot.ja4 == .count)
        #expect(prot.names?.first?.ja4 == .block)
        #expect(protection.lastRequest?.nodeRelativePath == "/cdn64/hosts/5/protection")
        #expect(protection.lastRequest?.jsonBody == .object(["waf": .bool(true), "ja4": .string("count")]))

        let dns = MockTransport(json: #"{"added":1,"skipped":["a A"],"excluded":["*.x"],"ipv4":"192.168.1.2","ipv6":"fd00::2"}"#)
        let result = try await Node64.mock(dns).proxy64.hosts.addLocalDNS(5, ipv4: "192.168.1.2")
        #expect(result.added == 1)
        #expect(result.skipped == ["a A"])
        #expect(dns.lastRequest?.httpMethod == "POST")
        #expect(dns.lastRequest?.nodeRelativePath == "/cdn64/hosts/5/localdns")
        #expect(dns.lastRequest?.jsonBody == .object(["ipv4": .string("192.168.1.2")]))
    }

    @Test("Online pause and own tunnel servers")
    func online() async throws {
        let pause = MockTransport(status: 204, body: Data())
        try await Node64.mock(pause).proxy64.online.pause(host: 2, paused: true)
        #expect(pause.lastRequest?.nodeRelativePath == "/cdn64/hosts/2/online/pause")
        #expect(pause.lastRequest?.jsonBody == .object(["paused": .bool(true)]))

        try await Node64.mock(pause).proxy64.online.pauseName(remoteID: 77, paused: false)
        #expect(pause.lastRequest?.nodeRelativePath == "/cdn64/online/names/77/pause")
        #expect(pause.lastRequest?.jsonBody == .object(["paused": .bool(false)]))

        let servers = MockTransport(json: Self.serversJSON)
        let got = try await Node64.mock(servers).proxy64.online.servers()
        #expect(got.count == 2)
        #expect(servers.lastRequest?.nodeRelativePath == "/cdn64/online/servers")
        _ = try await Node64.mock(servers).proxy64.online.updateServers(count: 1)
        #expect(servers.lastRequest?.httpMethod == "PUT")
        #expect(servers.lastRequest?.jsonBody == .object(["count": .number(1)]))
    }

    @Test("Protection statistics and release")
    func protectionAndRelease() async throws {
        let stats = MockTransport(json: """
        {"days":7,"ja4_global":"count","totals":{"blocked_list":1,"blocked_acl":2,"blocked_flood":3,"blocked_limit":4,
         "blocked_waf":5,"blocked_ja4":6,"ja4_hits":7,"blocked_ips":8,"conns":9,"conns_v4":10},
         "daily":[{"day":"2026-11-01"}],"ja4_top":[{"ja4":"t13d","hits":4}],
         "hosts":[{"id":1,"fqdn":"a.example.com","mode":3,"host_id":5,"blocked":2,"overload":1,"waf":true,"ja4":""}]}
        """)
        let result = try await Node64.mock(stats).proxy64.protection(days: 30)
        #expect(stats.lastRequest?.nodeRelativePath == "/cdn64/protection?days=30")
        #expect(result.ja4Global == .count)
        #expect(result.totals?.blockedWAF == 5)
        #expect(result.totals?.connsV4 == 10)
        #expect(result.ja4Top?.first?.hits == 4)
        #expect(result.hosts?.first?.hostID == 5)

        let release = MockTransport(json: #"{"allow":["1.2.3.4"],"deny":["5.6.7.8"],"denied":3}"#)
        let lists = try await Node64.mock(release).proxy64.release(ip: "1.2.3.4", from: .honeypot)
        #expect(lists.allow == ["1.2.3.4"])
        #expect(lists.denied == 3)
        #expect(release.lastRequest?.httpMethod == "POST")
        #expect(release.lastRequest?.nodeRelativePath == "/cdn64/release")
        #expect(release.lastRequest?.jsonBody == .object(["ip": .string("1.2.3.4"), "from": .string("honeypot")]))
    }

    @Test("Blocklists update sends deny; honeypot route and access list auth")
    func protectionInputs() async throws {
        let transport = MockTransport(json: "{}")
        _ = try await Node64.mock(transport).proxy64.blocklists.update(deny: ["9.9.9.9"])
        #expect(transport.lastRequest?.jsonBody == .object(["deny": .array([.string("9.9.9.9")])]))

        _ = try await Node64.mock(transport).proxy64.honeypot.update(.init(route: .init(aiBot: true, geo: false)))
        #expect(transport.lastRequest?.jsonBody == .object(["route": .object(["ai_bot": .bool(true), "geo": .bool(false)])]))

        let input = Node64.CDNAccessListInput(
            loginPage: true, auth: .authentik,
            forward: .init(address: "http://a:9000/auth", headers: ["X-User"], callback: "/cb"),
            passUser: true, addKey: "ci", removeKeys: ["abc"]
        )
        let accessTransport = MockTransport(json: #"{"id":1,"add_key":"n64k_secret"}"#)
        let created = try await Node64.mock(accessTransport).proxy64.accessLists.create(input)
        #expect(created.addKey == "n64k_secret")
        #expect(accessTransport.lastRequest?.jsonBody == .object([
            "login_page": .bool(true), "auth": .string("authentik"),
            "forward": .object(["address": .string("http://a:9000/auth"), "headers": .array([.string("X-User")]), "callback": .string("/cb")]),
            "pass_user": .bool(true), "add_key": .string("ci"), "remove_keys": .array([.string("abc")]),
        ]))
    }

    @Test("Location and advanced fields round-trip; stream bandwidth")
    func hostModels() throws {
        let json = """
        {"id":1,"kind":"stream","locations":[{"path":"/x","action":"respond","status":418,"body":"hi","content_type":"text/plain",
          "advanced":{"timeout_seconds":5,"max_body_mb":-1,"buffering":"off","request_headers":[{"name":"A","value":"b"}],"response_remove":["Server"]}}],
         "advanced":{"bw_down_mbit":100,"bw_up_mbit":50,"error_html":"e","error_override":true,"maintenance":true,
          "maintenance_html":"m","maintenance_style":"gear","only_locations":true,"target_path":"/r"}}
        """
        let host = try JSONDecoder().decode(Node64.ProxyHost.self, from: Data(json.utf8))
        #expect(host.kind == .stream)
        let location = try #require(host.locations?.first)
        #expect(location.action == .respond)
        #expect(location.advanced?.buffering == .off)
        #expect(host.advanced?.maintenanceStyle == .gear)
        #expect(host.advanced?.bwDownMbit == 100)
        #expect(host.advanced?.targetPath == "/r")

        let encoded = try JSONEncoder().encode(location)
        let back = try JSONDecoder().decode(Node64.CDNLocation.self, from: encoded)
        #expect(back == location)

        let stream = try JSONDecoder().decode(Node64.ProxyStream.self, from: Data(#"{"id":1,"bw_down_mbit":10,"bw_up_mbit":5}"#.utf8))
        #expect(stream.bwUpMbit == 5)
        let body = try JSONEncoder().encode(Node64.ProxyStreamInput(bwDownMbit: 1, onlineName: "x.example.com"))
        let object = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(object == .object(["bw_down_mbit": .number(1), "online_name": .string("x.example.com")]))
    }

    @Test("Edge proxy_protocol and edge/ui cert")
    func edge() async throws {
        let transport = MockTransport(json: #"{"config":{"proxy_protocol":"172.18.0.0/16"}}"#)
        let status = try await Node64.mock(transport).ports.edge.update(.init(proxyProtocol: "172.18.0.0/16"))
        #expect(status.config?.proxyProtocol == "172.18.0.0/16")
        #expect(transport.lastRequest?.jsonBody == .object(["proxy_protocol": .string("172.18.0.0/16")]))
    }

    @Test("DNS-01 check resolvers and run")
    func dnsCheck() async throws {
        let transport = MockTransport(json: #"{"resolvers":["192.168.1.1"]}"#)
        let got = try await Node64.mock(transport).certificates.dnsCheck()
        #expect(got.resolvers == ["192.168.1.1"])
        #expect(transport.lastRequest?.nodeRelativePath == "/certs/dns-check")

        _ = try await Node64.mock(transport).certificates.updateDNSCheck(resolvers: ["tls://dns.example"])
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["resolvers": .array([.string("tls://dns.example")])]))

        let run = MockTransport(json: #"{"paths":[{"name":"ipv64","direct":true,"ok":true,"detail":"d"}],"direct_ok":true,"public_ok":false,"ok":true}"#)
        let result = try await Node64.mock(run).certificates.runDNSCheck()
        #expect(result.directOK == true)
        #expect(result.publicOK == false)
        #expect(result.paths?.first?.direct == true)
        #expect(run.lastRequest?.httpMethod == "POST")
        #expect(run.lastRequest?.nodeRelativePath == "/certs/dns-check/run")
    }
}

@Suite("Node64 PROXY protocol and target HTTP fields")
struct Node64ProxyProtocolFieldTests {
    @Test("Host advanced and location fields round-trip")
    func hostFields() throws {
        let json = Data(#"{"advanced":{"target_http":"h2c","proxy_protocol":"v2","no_probe":true},"locations":[{"path":"/a","denied_redirect":"/login","advanced":{"target_http":"h1"}}]}"#.utf8)
        struct Wrapper: Codable, Equatable { var advanced: Node64.CDNAdvanced; var locations: [Node64.CDNLocation] }
        let value = try JSONDecoder().decode(Wrapper.self, from: json)
        #expect(value.advanced.targetHTTP == .h2c && value.advanced.proxyProtocol == .v2 && value.advanced.noProbe == true)
        #expect(value.locations[0].deniedRedirect == "/login" && value.locations[0].advanced?.targetHTTP == .h1)
        let again = try JSONDecoder().decode(Wrapper.self, from: JSONEncoder().encode(value))
        #expect(again == value)
    }

    @Test("Stream proxy_protocol decodes and encodes")
    func streamField() throws {
        let stream = try JSONDecoder().decode(Node64.ProxyStream.self, from: Data(#"{"id":1,"proxy_protocol":"v1"}"#.utf8))
        #expect(stream.proxyProtocol == .v1)
        let body = try JSONEncoder().encode(Node64.ProxyStreamInput(proxyProtocol: .off))
        #expect(String(decoding: body, as: UTF8.self) == #"{"proxy_protocol":""}"#)
    }
}
