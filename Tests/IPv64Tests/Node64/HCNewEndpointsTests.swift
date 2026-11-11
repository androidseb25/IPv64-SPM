import Foundation
import Testing
@testable import IPv64

@Suite("Node64 ipv64 channels, ascheck-all, items, honeypot watch")
struct Node64HCNewEndpointsTests {
    @Test("ipv64 channels: CRUD, test and verification")
    func ipv64Channels() async throws {
        let channel = #"{"id":3,"type":"ipv64_mail","name":"Mail","enabled":true,"default":false,"verified":false,"lang":"de","notify_down":true,"notify_up":true,"config":{"email":"a@b.de"},"last_error":"x"}"#
        let transport = MockTransport(json: channel)
        let api = Node64.mock(transport).hc.ipv64Channels

        let got = try await api.get(3)
        #expect(got.type == .ipv64Mail && got.verified == false && got.notifyDown == true)
        #expect(got.config?["email"] == .string("a@b.de"))
        #expect(transport.lastRequest?.nodeRelativePath == "/ipv64/channels/3")

        _ = try await api.create(.init(type: .ipv64Mail, name: "Mail", config: ["email": .string("a@b.de")]))
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.jsonBody == .object([
            "type": .string("ipv64_mail"), "name": .string("Mail"), "config": .object(["email": .string("a@b.de")]),
        ]))

        _ = try await api.update(3, .init(isDefault: true))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["default": .bool(true)]))

        _ = try await api.verify(3, code: "123456")
        #expect(transport.lastRequest?.nodeRelativePath == "/ipv64/channels/3/verify")
        #expect(transport.lastRequest?.jsonBody == .object(["code": .string("123456")]))

        let testTransport = MockTransport(json: #"{"ok":true}"#)
        let result = try await Node64.mock(testTransport).hc.ipv64Channels.sendTest(3)
        #expect(result.ok == true)
        #expect(testTransport.lastRequest?.nodeRelativePath == "/ipv64/channels/3/test")

        let empty = MockTransport(status: 202)
        try await Node64.mock(empty).hc.ipv64Channels.sendVerification(3)
        #expect(empty.lastRequest?.nodeRelativePath == "/ipv64/channels/3/verify/send")
        let gone = MockTransport(status: 204)
        try await Node64.mock(gone).hc.ipv64Channels.delete(3)
        #expect(gone.lastRequest?.httpMethod == "DELETE")

        let listTransport = MockTransport(json: "[\(channel)]")
        let list = try await Node64.mock(listTransport).hc.ipv64Channels.list()
        #expect(list.first?.id == 3)
        #expect(listTransport.lastRequest?.nodeRelativePath == "/ipv64/channels")
    }

    @Test("Status page items")
    func statusPageItems() async throws {
        let transport = MockTransport(json: #"{"id":4,"title":"S"}"#)
        let page = try await Node64.mock(transport).hc.statusPages.addItems(4, .init(
            groupID: 0, tokens: ["t1"]
        ))
        #expect(page.id == 4)
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/status-pages/4/items")
        #expect(transport.lastRequest?.jsonBody == .object([
            "group_id": .number(0), "tokens": .array([.string("t1")]),
        ]))
    }

    @Test("Honeypot watch and certificate")
    func honeypot() async throws {
        let list = MockTransport(json: """
        {"limits":{"max":5,"min_prefix_v4":24,"min_prefix_v6":48},
         "networks":[{"id":1,"cidr":"203.0.113.0/24","label":"x","verified":true,"created_at":"2026-10-01"}],
         "dyndns":[{"ip":"203.0.113.9","domain":"a.ipv64.de"}],"full":false,"running":true,"state":{"last":1}}
        """)
        let watch = try await Node64.mock(list).honeypot.watch.list()
        #expect(watch.limits?.minPrefixV4 == 24 && watch.networks?.first?.verified == true)
        #expect(watch.dyndns?.first?.domain == "a.ipv64.de" && watch.state?["last"] == .number(1))
        #expect(list.lastRequest?.nodeRelativePath == "/honeypot/watch")

        let add = MockTransport(status: 201, json: #"{"id":2,"cidr":"198.51.100.1/32"}"#)
        let network = try await Node64.mock(add).honeypot.watch.add(cidr: "198.51.100.1", label: "ip")
        #expect(network.id == 2)
        #expect(add.lastRequest?.jsonBody == .object(["cidr": .string("198.51.100.1"), "label": .string("ip")]))

        let remove = MockTransport(status: 204)
        try await Node64.mock(remove).honeypot.watch.remove(2)
        #expect(remove.lastRequest?.httpMethod == "DELETE")
        #expect(remove.lastRequest?.nodeRelativePath == "/honeypot/watch/2")

        let check = MockTransport(json: #"{"new_hits":3,"state":{}}"#)
        let hits = try await Node64.mock(check).honeypot.watch.check()
        #expect(hits.newHits == 3)
        #expect(check.lastRequest?.nodeRelativePath == "/honeypot/watch/check")

        let cert = MockTransport(status: 202, json: """
        {"cert_id":9,"names":["a.x.ipv64.de"],"selected":true,
         "dns":[{"name":"a.x.ipv64.de","type":"A","result":"created"}],"dns_error":"e"}
        """)
        let issued = try await Node64.mock(cert).honeypot.certificate(.init(domain: "x.ipv64.de", names: ["a"], dnsTargets: ["203.0.113.9"]))
        #expect(issued.certID == 9 && issued.dns?.first?.result == "created" && issued.dnsError == "e")
        #expect(cert.lastRequest?.nodeRelativePath == "/honeypot/cert")
        #expect(cert.lastRequest?.jsonBody == .object([
            "domain": .string("x.ipv64.de"), "names": .array([.string("a")]), "dns_targets": .array([.string("203.0.113.9")]),
        ]))
    }
}
