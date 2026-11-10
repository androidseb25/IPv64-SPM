import Foundation
import Testing
@testable import IPv64

@Suite("HC2StatusPages")
struct HC2StatusPagesTests {
    static let pageJSON = """
    {"id":7,"slug":"mein-status","url":"https://ipv64.net/healthchecks2/status/mein-status",
     "json_url":"https://ipv64.net/healthchecks2/status/mein-status.json","title":"Status","description":"",
     "lang":"de","theme":"future","layout":"cards","published":true,"show_history":true,"autorefresh":false,
     "preview_url":"https://ipv64.net/healthchecks2/status/mein-status?preview=x",
     "groups":[{"name":"Web","tokens":["a","b"]},{"tokens":["c"]}],
     "created_at":"2026-10-10T12:00:00+02:00","updated_at":"2026-10-11T12:00:00+02:00"}
    """
    static let noticeJSON = """
    {"id":3,"kind":"incident","title":"Outage","body":"Investigating","resolved":false,
     "created_at":"2026-10-10T12:00:00+02:00","resolved_at":null}
    """

    @Test("page decodes with groups, dates and unknown enum values")
    func decode() throws {
        let page = try IPv64Coding.makeDecoder().decode(HC2StatusPage.self, from: Data(Self.pageJSON.utf8))
        #expect(page.id == 7)
        #expect(page.jsonURL?.hasSuffix(".json") == true)
        #expect(page.lang == .de)
        #expect(page.theme == HC2StatusPageTheme(rawValue: "future"))
        #expect(page.layout == .cards)
        #expect(page.showHistory == true)
        #expect(page.groups == [HC2StatusGroup(name: "Web", tokens: ["a", "b"]), HC2StatusGroup(tokens: ["c"])])
        #expect(page.createdAt != nil && page.updatedAt != nil)
    }

    @Test("notice decodes")
    func decodeNotice() throws {
        let notice = try IPv64Coding.makeDecoder().decode(HC2StatusNotice.self, from: Data(Self.noticeJSON.utf8))
        #expect(notice.kind == .incident)
        #expect(notice.resolved == false)
        #expect(notice.createdAt != nil)
        #expect(notice.resolvedAt == nil)
    }

    @Test("list and get")
    func listGet() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.pageJSON)]}"#)
        #expect(try await IPv64.mock(transport).hc2.statusPages.list().count == 1)
        #expect(transport.lastRequest?.httpMethod == "GET")
        #expect(transport.lastRequest?.relativePath == "/hc2/status-pages")

        let getTransport = MockTransport(json: #"{"data":\#(Self.pageJSON)}"#)
        _ = try await IPv64.mock(getTransport).hc2.statusPages.get(7)
        #expect(getTransport.lastRequest?.relativePath == "/hc2/status-pages/7")
    }

    @Test("create sends only the set fields")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.pageJSON)}"#)
        let page = try await IPv64.mock(transport).hc2.statusPages.create(
            HC2StatusPageInput(title: "Status", groups: [HC2StatusGroup(name: "Web", tokens: ["a"])], layout: .cards, showHistory: true)
        )
        #expect(page.id == 7)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/hc2/status-pages")
        #expect(request.jsonBody == .object([
            "title": "Status",
            "groups": .array([.object(["name": "Web", "tokens": .array(["a"])])]),
            "layout": "cards",
            "show_history": true,
        ]))
    }

    @Test("update is a PATCH with only the set fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.pageJSON)}"#)
        _ = try await IPv64.mock(transport).hc2.statusPages.update(7, HC2StatusPageInput(theme: .dark, published: false))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.relativePath == "/hc2/status-pages/7")
        #expect(request.jsonBody == .object(["theme": "dark", "published": false]))
    }

    @Test("delete")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).hc2.statusPages.delete(7)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.relativePath == "/hc2/status-pages/7")
    }

    @Test("list notices")
    func notices() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.noticeJSON)]}"#)
        let notices = try await IPv64.mock(transport).hc2.statusPages.notices(7)
        #expect(notices.first?.id == 3)
        #expect(transport.lastRequest?.httpMethod == "GET")
        #expect(transport.lastRequest?.relativePath == "/hc2/status-pages/7/notices")
    }

    @Test("create notice")
    func createNotice() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.noticeJSON)}"#)
        _ = try await IPv64.mock(transport).hc2.statusPages.createNotice(7, HC2StatusNoticeInput(kind: .incident, title: "Outage"))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/hc2/status-pages/7/notices")
        #expect(request.jsonBody == .object(["kind": "incident", "title": "Outage"]))
    }

    @Test("update and delete notice")
    func updateDeleteNotice() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.noticeJSON)}"#)
        _ = try await IPv64.mock(transport).hc2.statusPages.updateNotice(7, notice: 3, HC2StatusNoticeInput(resolved: true))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.relativePath == "/hc2/status-pages/7/notices/3")
        #expect(request.jsonBody == .object(["resolved": true]))

        let deleteTransport = MockTransport(status: 204)
        try await IPv64.mock(deleteTransport).hc2.statusPages.deleteNotice(7, notice: 3)
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
        #expect(deleteTransport.lastRequest?.relativePath == "/hc2/status-pages/7/notices/3")
    }
}
