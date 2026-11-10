import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DNS64 allow lists, deny list, services, docker, TSIG")
struct Node64DNS64FilteringTests {
    @Test("Allow lists list, add, add many, remove")
    func allowLists() async throws {
        let list = MockTransport(json: #"[{"name":"A","url":"https://x/a.txt","rules":3,"enabled":true}]"#)
        let items = try await Node64.mock(list).dns64.allowLists.list()
        #expect(list.lastRequest?.nodeRelativePath == "/dns64/allowlists")
        #expect(items.first?.enabled == true)

        let add = MockTransport(status: 201, json: #"{"allow_lists":[{"url":"https://x/a.txt","enabled":true}],"mdns":true,"docker":true,"docker_ip":"10.0.0.2"}"#)
        let settings = try await Node64.mock(add).dns64.allowLists.add("https://x/a.txt", name: "A")
        #expect(add.lastRequest?.httpMethod == "POST")
        #expect(add.lastRequest?.jsonBody == .object(["url": .string("https://x/a.txt"), "name": .string("A")]))
        #expect(settings.allowLists?.first?.url == "https://x/a.txt")
        #expect(settings.mdns == true)
        #expect(settings.docker == true)
        #expect(settings.dockerIP == "10.0.0.2")

        let many = MockTransport(status: 201, json: #"{"added":["https://x/b"],"duplicates":[],"invalid":["zz"]}"#)
        let result = try await Node64.mock(many).dns64.allowLists.add(urls: ["https://x/b", "zz"])
        #expect(many.lastRequest?.jsonBody?["urls"] != nil)
        #expect(many.lastRequest?.jsonBody?["url"] == nil)
        #expect(result.invalid == ["zz"])

        let remove = MockTransport(json: #"{}"#)
        _ = try await Node64.mock(remove).dns64.allowLists.remove("https://x/a.txt")
        #expect(remove.lastRequest?.httpMethod == "DELETE")
        #expect(remove.lastRequest?.nodeRelativePath.hasPrefix("/dns64/allowlists?url=") == true)

        let lists = MockTransport(status: 201, json: #"{"added":["u"]}"#)
        _ = try await Node64.mock(lists).dns64.lists.add(urls: ["u"])
        #expect(lists.lastRequest?.nodeRelativePath == "/dns64/lists")
    }

    @Test("Settings input encodes new fields")
    func settingsInput() async throws {
        let transport = MockTransport(json: #"{}"#)
        _ = try await Node64.mock(transport).dns64.updateSettings(
            .init(allowLists: [.init(url: "u")], mdns: true, docker: false, dockerIP: "10.0.0.2")
        )
        let body = transport.lastRequest?.jsonBody
        #expect(body?["mdns"] == .bool(true))
        #expect(body?["docker"] == .bool(false))
        #expect(body?["docker_ip"]?.stringValue == "10.0.0.2")
        #expect(body?["allow_lists"] != nil)
        #expect(body?["port"] == nil)
    }

    @Test("Deny list list, add, remove, replace")
    func denylist() async throws {
        let list = MockTransport(json: #"[{"domain":"ads.example.com","addedAt":"2026-10-27T08:00:00Z"}]"#)
        let entries = try await Node64.mock(list).dns64.denylist.list()
        #expect(entries.first?.domain == "ads.example.com")
        #expect(entries.first?.addedAt != nil)

        let add = MockTransport(json: #"{"domain":"ads.example.com"}"#)
        let added = try await Node64.mock(add).dns64.denylist.add("Ads.example.com")
        #expect(add.lastRequest?.jsonBody == .object(["domain": .string("Ads.example.com")]))
        #expect(added.domain == "ads.example.com")

        let remove = MockTransport(status: 204, body: Data())
        try await Node64.mock(remove).dns64.denylist.remove("ads.example.com")
        #expect(remove.lastRequest?.nodeRelativePath == "/dns64/denylist?domain=ads.example.com")

        let put = MockTransport(json: #"{"total":2,"added":1,"removed":0,"duplicates":0,"invalid":["!!"]}"#)
        let result = try await Node64.mock(put).dns64.denylist.replace(["a.example", "b.example", "!!"])
        #expect(put.lastRequest?.httpMethod == "PUT")
        #expect(put.lastRequest?.jsonBody?["domains"] != nil)
        #expect(result.total == 2)
        #expect(result.invalid == ["!!"])
    }

    @Test("Services, docker and top list decode")
    func readOnly() async throws {
        let services = MockTransport(json: """
        {"categories":["social"],"groups":["ai"],"services":[{"key":"svc:tiktok","id":"tiktok","name":"TikTok","group":"social","domains":["tiktok.com"]}]}
        """)
        let s = try await Node64.mock(services).dns64.services()
        #expect(services.lastRequest?.nodeRelativePath == "/dns64/services")
        #expect(s.services?.first?.key == "svc:tiktok")
        #expect(s.services?.first?.id == "tiktok")

        let docker = MockTransport(json: """
        {"enabled":true,"connected":true,"host":"unix:///var/run/docker.sock","synced":"2026-10-27T08:00:00Z",
         "containers":[{"container":"web","state":"running","names":["web.lan"],"addrs":["172.17.0.2"],"problem":"taken","problem_name":"web.lan"}]}
        """)
        let d = try await Node64.mock(docker).dns64.docker()
        #expect(docker.lastRequest?.nodeRelativePath == "/dns64/docker")
        #expect(d.synced != nil)
        #expect(d.containers?.first?.problem == .taken)
        #expect(d.containers?.first?.problemName == "web.lan")

        let top = MockTransport(json: #"{"items":[{"name":"a.com","count":5,"blocked":2}],"total":40}"#)
        let page = try await Node64.mock(top).dns64.topList(
            kind: .blocked, range: .last7Days, query: "a", sort: .name, direction: .ascending, limit: 10, offset: 20
        )
        let path = top.lastRequest?.nodeRelativePath ?? ""
        #expect(path.hasPrefix("/dns64/top/list?"))
        for part in ["kind=blocked", "range=7d", "q=a", "sort=name", "dir=asc", "limit=10", "offset=20"] {
            #expect(path.contains(part))
        }
        #expect(page.total == 40)
        #expect(page.items?.first?.count == 5)
    }

    @Test("TSIG get and regenerate")
    func tsig() async throws {
        let json = #"{"zone":"home.lan","dynamic":true,"algorithm":"hmac-sha256","tsig_name":"node64-home.lan","tsig_secret":"c2VjcmV0"}"#
        let get = MockTransport(json: json)
        let key = try await Node64.mock(get).dns64.zones.tsig(4)
        #expect(get.lastRequest?.httpMethod == "GET")
        #expect(get.lastRequest?.nodeRelativePath == "/dns64/zones/4/tsig")
        #expect(key.tsigSecret == "c2VjcmV0")
        #expect(key.tsigName == "node64-home.lan")

        let post = MockTransport(json: json)
        _ = try await Node64.mock(post).dns64.zones.regenerateTSIG(4)
        #expect(post.lastRequest?.httpMethod == "POST")
        #expect(post.lastRequest?.nodeRelativePath == "/dns64/zones/4/tsig")
    }

    @Test("Group member tags: decode, create, patch, unassign")
    func memberTags() async throws {
        let json = #"{"id":9,"group_id":3,"kind":"mac","value":"aa:bb","label":"tablet","tags":["kid","ipad"]}"#
        let create = MockTransport(status: 201, json: json)
        let member = try await Node64.mock(create).dns64.groups.members.create(group: 3, kind: .mac, value: "aa:bb", tags: ["kid", "ipad"])
        #expect(member.tags == ["kid", "ipad"])
        #expect(create.lastRequest?.jsonBody?["tags"] != nil)

        let patch = MockTransport(json: json)
        let updated = try await Node64.mock(patch).dns64.groups.members.update(9, label: "tablet")
        #expect(patch.lastRequest?.httpMethod == "PATCH")
        #expect(patch.lastRequest?.nodeRelativePath == "/dns64/groups/members/9")
        #expect(patch.lastRequest?.jsonBody == .object(["label": .string("tablet")]))
        #expect(updated.tags?.count == 2)

        let unassign = MockTransport(status: 204)
        try await Node64.mock(unassign).dns64.groups.unassign(mac: "aa:bb")
        #expect(unassign.lastRequest?.httpMethod == "POST")
        #expect(unassign.lastRequest?.nodeRelativePath == "/dns64/groups/unassign")
        #expect(unassign.lastRequest?.jsonBody == .object(["mac": .string("aa:bb")]))
    }

    @Test("Upstreams decode mDNS, local domains and pausedUntil")
    func upstreams() throws {
        let json = """
        {"mode":"fastest","servers":[{"url":"https://u","pausedUntil":"2026-10-27T08:00:00Z"}],
         "mdns":{"on":true,"queries":10,"answered":4,"responders":-1,"probed_at":"2026-10-27T08:00:00Z"},
         "localDomains":["lan","fritz.box"],"count":1}
        """
        let value = try JSONDecoder.node64Test.decode(Node64.DNS64Upstreams.self, from: Data(json.utf8))
        #expect(value.mdns?.on == true)
        #expect(value.mdns?.responders == -1)
        #expect(value.mdns?.probedAt != nil)
        #expect(value.localDomains == ["lan", "fritz.box"])
        #expect(value.servers?.first?.pausedUntil != nil)
    }
}

extension JSONDecoder {
    fileprivate static var node64Test: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
