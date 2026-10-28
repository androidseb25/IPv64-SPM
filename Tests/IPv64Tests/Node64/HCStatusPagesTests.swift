import Foundation
import Testing
@testable import IPv64

@Suite("Node64 status pages")
struct Node64HCStatusPagesTests {
    static let pageJSON = """
    {"id":3,"slug":"main","title":"Status","description":"d","enabled":true,"publish_node":true,
     "layout":"tiles","theme":"auto","lang":"","days":90,"show_uptime":true,"show_history":true,
     "refresh_sec":60,"has_password":false,"noindex":true,"powered_by":true,
     "groups":[{"id":1,"name":"Web","items":[{"id":7,"token":"abc","label":"Site"}]}],
     "created_at":"2026-10-27T08:00:00Z","updated_at":"2026-10-27T09:00:00Z",
     "hc_groups":false,"has_logo":true,"logo_updated":"2026-10-27T09:00:00Z"}
    """

    @Test("StatusPage decodes with groups and items")
    func decodePage() async throws {
        let transport = MockTransport(json: "[\(Self.pageJSON)]")
        let pages = try await Node64.mock(transport).hc.statusPages.list()
        let page = try #require(pages.first)
        #expect(page.id == 3)
        #expect(page.layout == .tiles)
        #expect(page.publishNode == true)
        #expect(page.groups?.first?.items?.first?.token == "abc")
        #expect(page.logoUpdated != nil)
        #expect(transport.lastRequest?.nodeRelativePath == "/status-pages")
    }

    @Test("StatusNotice decodes with updates")
    func decodeNotice() async throws {
        let transport = MockTransport(json: """
        [{"id":5,"page_id":3,"title":"Maintenance","level":"warning","created_at":"2026-10-27T08:00:00Z",
          "updated_at":"2026-10-27T08:00:00Z","updates":[{"id":1,"time":"2026-10-27T08:00:00Z","text":"Start"}]}]
        """)
        let notices = try await Node64.mock(transport).hc.statusPages.notices.list(page: 3)
        #expect(notices.first?.level == .warning)
        #expect(notices.first?.pageID == 3)
        #expect(notices.first?.resolvedAt == nil)
        #expect(notices.first?.updates?.first?.text == "Start")
        #expect(transport.lastRequest?.nodeRelativePath == "/status-pages/3/notices")
    }

    @Test("Create sends only set fields")
    func create() async throws {
        let transport = MockTransport(status: 201, json: Self.pageJSON)
        let input = Node64.StatusPageInput(
            title: "Status",
            theme: .dark,
            groups: [.init(name: "Web", items: [.init(token: "abc")])]
        )
        _ = try await Node64.mock(transport).hc.statusPages.create(input)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.jsonBody == .object([
            "title": .string("Status"),
            "theme": .string("dark"),
            "groups": .array([.object(["name": .string("Web"), "items": .array([.object(["token": .string("abc")])])])]),
        ]))
    }

    @Test("Notice requests")
    func noticeRequests() async throws {
        let transport = MockTransport(json: #"{"id":5,"title":"x"}"#)
        let api = Node64.mock(transport).hc.statusPages.notices
        _ = try await api.create(page: 3, .init(title: "x", level: .danger))
        #expect(transport.lastRequest?.jsonBody == .object(["title": .string("x"), "level": .string("danger")]))
        _ = try await api.update(5, page: 3, .init(text: "done", resolve: true))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/status-pages/3/notices/5")
        #expect(request.jsonBody == .object(["text": .string("done"), "resolve": .bool(true)]))

        let deleted = MockTransport(status: 204)
        try await Node64.mock(deleted).hc.statusPages.notices.delete(5, page: 3)
        #expect(deleted.lastRequest?.httpMethod == "DELETE")
        #expect(deleted.lastRequest?.nodeRelativePath == "/status-pages/3/notices/5")
    }

    @Test("Logo upload sends raw body and content type")
    func logo() async throws {
        let transport = MockTransport(json: Self.pageJSON)
        let data = Data([1, 2, 3])
        _ = try await Node64.mock(transport).hc.statusPages.setLogo(3, data: data, contentType: "image/png")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/status-pages/3/logo")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/png")
        #expect(request.httpBody == data)
    }

    @Test("Delete returns on 204")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).hc.statusPages.delete(3)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        try await Node64.mock(transport).hc.statusPages.removeLogo(3)
        #expect(transport.lastRequest?.nodeRelativePath == "/status-pages/3/logo")
    }

    @Test("Error document becomes Node64Error.api")
    func error() async throws {
        let transport = MockTransport(
            status: 409,
            json: #"{"error":"slug taken","field":"slug","key":"hc.status.err.slug_taken"}"#,
            headers: ["Content-Type": "application/json"]
        )
        await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.statusPages.create(title: "x")
        }
    }
}
