import Foundation
import Testing
@testable import IPv64

@Suite("Domains")
struct DomainsTests {
    static let detailJSON = """
    {"id":17597,"name":"beispiel.ipv64.de","kind":"dyndns","zone":"ipv64.de","wildcard":true,"ignore":"none","ipv6_prefix":null,
    "active":true,"update_token":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","update_count":1200,
    "created_at":"2026-10-10T12:00:00+02:00","updated_at":null,
    "records":[{"id":4711,"domain_id":17597,"domain":"beispiel.ipv64.de","prefix":"nas","fqdn":"nas.beispiel.ipv64.de","type":"A","content":"203.0.113.10","ttl":60,"state":"active","pending_dns":false,"token":"tok"}]}
    """

    @Test("GET /domains?kind= decodes domains")
    func list() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":17597,"name":"beispiel.ipv64.de","kind":"own","zone":"ipv64.de","wildcard":false,"ignore":"ipv6","ipv6_prefix":"2001:db8::/56","active":true,"update_token":"t","update_count":3}]}
        """)
        let domains = try await IPv64.mock(transport).domains.list(kind: .own)

        #expect(domains.first?.kind == .own)
        #expect(domains.first?.ignore == .ipv6)
        #expect(domains.first?.ipv6Prefix == "2001:db8::/56")
        #expect(transport.lastRequest?.relativePath == "/domains?kind=own")
    }

    @Test("GET /domains/{domain} decodes records and percent-encodes the path")
    func get() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.detailJSON)}"#)
        let detail = try await IPv64.mock(transport).domains.get("a b/c.ipv64.de")

        #expect(detail.id == 17597)
        #expect(detail.updatedAt == nil)
        #expect(detail.records?.first?.fqdn == "nas.beispiel.ipv64.de")
        #expect(transport.lastRequest?.relativePath == "/domains/a%20b%2Fc.ipv64.de")
    }

    @Test("POST /domains sends name and own")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.detailJSON)}"#)
        _ = try await IPv64.mock(transport).domains.create(name: "meinname.ipv64.de", own: false)

        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.jsonBody == .object(["name": "meinname.ipv64.de", "own": false]))
    }

    @Test("PATCH /domains/{domain} sends only provided fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.detailJSON)}"#)
        _ = try await IPv64.mock(transport).domains.update("beispiel.ipv64.de", wildcard: true, ignore: .ipv4)

        #expect(transport.lastRequest?.httpMethod == "PATCH")
        #expect(transport.lastRequest?.relativePath == "/domains/beispiel.ipv64.de")
        #expect(transport.lastRequest?.jsonBody == .object(["wildcard": true, "ignore": "ipv4"]))
    }

    @Test("DELETE /domains/{domain} accepts 204")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).domains.delete("beispiel.ipv64.de")
        #expect(transport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("POST rotate-token returns a Domain")
    func rotateToken() async throws {
        let transport = MockTransport(json: """
        {"data":{"id":1,"name":"x.ipv64.de","kind":"dyndns","update_token":"new"}}
        """)
        let domain = try await IPv64.mock(transport).domains.rotateToken("x.ipv64.de")

        #expect(domain.updateToken == "new")
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.relativePath == "/domains/x.ipv64.de/rotate-token")
    }

    @Test("POST reset returns a DomainDetail")
    func reset() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.detailJSON)}"#)
        let detail = try await IPv64.mock(transport).domains.reset("beispiel.ipv64.de")

        #expect(detail.records?.count == 1)
        #expect(transport.lastRequest?.relativePath == "/domains/beispiel.ipv64.de/reset")
    }

    @Test("POST dyndns sends addresses and decodes results")
    func dyndns() async throws {
        let transport = MockTransport(json: """
        {"data":{"domain":"beispiel.ipv64.de","prefix":"nas","changed":true,"results":[{"ip":"203.0.113.10","type":"A","result":"updated"},{"ip":"2001:db8::10","type":"AAAA","result":"created"}]}}
        """)
        let result = try await IPv64.mock(transport).domains.updateDynDNS(
            "beispiel.ipv64.de", ipv4: "203.0.113.10", ipv6: "2001:db8::10", prefix: "nas"
        )

        #expect(result.changed == true)
        #expect(result.results?.first?.result == .updated)
        #expect(result.results?.last?.type == .aaaa)
        #expect(transport.lastRequest?.relativePath == "/domains/beispiel.ipv64.de/dyndns")
        #expect(transport.lastRequest?.jsonBody == .object(["ipv4": "203.0.113.10", "ipv6": "2001:db8::10", "prefix": "nas"]))
    }

    @Test("Domain errors surface their code")
    func notFound() async throws {
        let transport = MockTransport(status: 404, json: """
        {"type":"about:blank","title":"Not Found","status":404,"detail":"No such domain.","code":"domain_not_found"}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).domains.get("nope.ipv64.de")
        }
        #expect(error?.code == "domain_not_found")
    }
}
