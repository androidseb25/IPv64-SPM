import Foundation
import Testing
@testable import IPv64

@Suite("Node64 status page view")
struct StatusPageViewTests {
    @Test("view sends GET with lang and keeps the raw JSON")
    func view() async throws {
        let t = MockTransport(json: #"{"overall":"ok","sections":[{"section":"systems","groups":[]}]}"#)
        let v = try await Node64.mock(t).hc.statusPages.view(5, lang: .de)
        #expect(t.lastRequest?.httpMethod == "GET")
        #expect(t.lastRequest?.nodeRelativePath == "/status-pages/5/view?lang=de")
        #expect(v["overall"]?.stringValue == "ok")
        #expect(v["sections"] != nil)
    }
}
