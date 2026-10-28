import Foundation
import Testing
@testable import IPv64

@Suite("StatusPages")
struct StatusPagesTests {
    static let pageJSON = """
    {"id":1053,"name":"Mein Status","slug":"meinstatus","url":"https://ipv64.net/status/meinstatus","description":"",
     "password_protected":false,"design":1,"autorefresh":true,"healthchecks":["Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z"],
     "created_at":"2026-10-10T12:00:00+02:00","last_viewed_at":null}
    """

    @Test("StatusPage schema decodes")
    func decode() throws {
        let page = try IPv64Coding.makeDecoder().decode(StatusPage.self, from: Data(Self.pageJSON.utf8))
        #expect(page.id == 1053)
        #expect(page.slug == "meinstatus")
        #expect(page.passwordProtected == false)
        #expect(page.healthchecks?.count == 1)
        #expect(page.lastViewedAt == nil)
    }

    @Test("create sends the input as JSON")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.pageJSON)}"#)
        let page = try await IPv64.mock(transport).statusPages.create(
            StatusPageInput(name: "Mein Status", healthchecks: ["tok"])
        )
        #expect(page.id == 1053)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/status-pages")
        #expect(request.jsonBody == .object(["name": "Mein Status", "healthchecks": .array(["tok"])]))
    }

    @Test("update keeps an empty password to make the page public")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.pageJSON)}"#)
        _ = try await IPv64.mock(transport).statusPages.update(1053, StatusPageInput(password: "", design: 2))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.relativePath == "/status-pages/1053")
        #expect(request.jsonBody == .object(["password": "", "design": .number(2)]))
    }

    @Test("list, get and delete")
    func listGetDelete() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.pageJSON)]}"#)
        #expect(try await IPv64.mock(transport).statusPages.list().count == 1)
        #expect(transport.lastRequest?.relativePath == "/status-pages")

        let getTransport = MockTransport(json: #"{"data":\#(Self.pageJSON)}"#)
        _ = try await IPv64.mock(getTransport).statusPages.get(1053)
        #expect(getTransport.lastRequest?.relativePath == "/status-pages/1053")

        let deleteTransport = MockTransport(status: 204)
        try await IPv64.mock(deleteTransport).statusPages.delete(1053)
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("404 problem+json becomes IPv64Error.api")
    func notFound() async throws {
        let transport = MockTransport(status: 404, json: """
        {"type":"https://ipv64.net/api/v2/errors#status_page_not_found","title":"Not Found","status":404,
         "detail":"Unknown.","code":"status_page_not_found"}
        """)
        do {
            _ = try await IPv64.mock(transport).statusPages.get(1)
            Issue.record("Expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "status_page_not_found")
        }
    }
}
