import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DNS64 groups")
struct Node64DNS64GroupsTests {
    @Test("Group decodes with members, rules, schedules and state")
    func decodeGroup() throws {
        let json = """
        {"id":3,"name":"Kids","position":1,
         "members":[{"id":9,"group_id":3,"kind":"mac","value":"aa:bb:cc:dd:ee:ff","label":"tablet"}],
         "lists_mode":"custom","lists":["https://example.com/list.txt"],
         "categories":["social","games"],
         "domains":[{"id":4,"group_id":3,"domain":"tiktok.com","action":"block"}],
         "safesearch":true,"youtube":"strict","bypass":false,"hold":"block","hold_until":"2026-10-28T07:00:00Z",
         "schedules":[{"id":5,"group_id":3,"label":"Night","days":[1,2],"start":"21:00","end":"07:00","action":"off","enabled":true}],
         "state":{"internet_off":true,"free":false,"by_button":true,"until_released":false,"until":"2026-10-28T07:00:00Z","schedule":"Night"},
         "uid":"abc"}
        """
        let group = try JSONDecoder.node64Test.decode(Node64.DNS64Group.self, from: Data(json.utf8))
        #expect(group.id == 3)
        #expect(group.listsMode == .custom)
        #expect(group.categories == [.social, .games])
        #expect(group.members?.first?.kind == .mac)
        #expect(group.members?.first?.groupID == 3)
        #expect(group.domains?.first?.action == .block)
        #expect(group.youtube == .strict)
        #expect(group.hold == .block)
        #expect(group.schedules?.first?.days == [1, 2])
        #expect(group.state?.internetOff == true)
        #expect(group.state?.until != nil)
        #expect(group.uid == "abc")
    }

    @Test("Device and device name decode")
    func decodeDevice() throws {
        let device = try JSONDecoder.node64Test.decode(
            Node64.DNS64Device.self,
            from: Data(#"{"ip":"192.168.1.5","name":"tv","mac":"aa","group":"Kids","group_id":3,"queries":12,"last_seen":"2026-10-27T10:00:00Z"}"#.utf8)
        )
        #expect(device.groupID == 3)
        #expect(device.queries == 12)
        #expect(device.lastSeen != nil)
        let name = try JSONDecoder.node64Test.decode(
            Node64.DNS64DeviceName.self,
            from: Data(#"{"name":"tablet-lea.home.lan","ips":["10.0.0.2"]}"#.utf8)
        )
        #expect(name.ips == ["10.0.0.2"])
    }

    @Test("Creating a group posts the name")
    func createGroup() async throws {
        let transport = MockTransport(status: 201, json: #"{"id":1,"name":"Kids"}"#)
        let group = try await Node64.mock(transport).dns64.groups.create(name: "Kids")
        #expect(group.id == 1)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.nodeRelativePath == "/dns64/groups")
        #expect(request.jsonBody?["name"]?.stringValue == "Kids")
    }

    @Test("Renaming returns 204 without content")
    func renameGroup() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).dns64.groups.rename(7, to: "Neu")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/dns64/groups/7")
    }

    @Test("Rules body uses snake_case and omits nil")
    func rules() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).dns64.groups.updateRules(2, listsMode: .custom, categories: [.adult], youtube: .off)
        let request = try #require(transport.lastRequest)
        #expect(request.nodeRelativePath == "/dns64/groups/2/rules")
        #expect(request.jsonBody?["lists_mode"]?.stringValue == "custom")
        #expect(request.jsonBody?["youtube"]?.stringValue == "off")
        #expect(request.jsonBody?["bypass"] == nil)
    }

    @Test("Hold sends mode, minutes and until_morning")
    func hold() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).dns64.groups.hold(2, mode: .block, minutes: 30, untilMorning: false)
        let request = try #require(transport.lastRequest)
        #expect(request.nodeRelativePath == "/dns64/groups/2/hold")
        #expect(request.jsonBody?["mode"]?.stringValue == "block")
        #expect(request.jsonBody?["minutes"]?.intValue == 30)
        #expect(request.jsonBody?["until_morning"]?.boolValue == false)
    }

    @Test("Member, domain and schedule requests")
    func nested() async throws {
        let member = MockTransport(status: 201, json: #"{"id":1,"kind":"ip","value":"10.0.0.1"}"#)
        let added = try await Node64.mock(member).dns64.groups.members.create(group: 4, kind: .ip, value: "10.0.0.1")
        #expect(added.kind == .ip)
        #expect(member.lastRequest?.nodeRelativePath == "/dns64/groups/4/members")

        let domain = MockTransport(status: 201, json: #"{"id":1,"domain":"a.com","action":"allow"}"#)
        _ = try await Node64.mock(domain).dns64.groups.domains.create(group: 4, domain: "a.com", action: .allow)
        #expect(domain.lastRequest?.jsonBody?["action"]?.stringValue == "allow")

        let schedule = MockTransport(status: 201, json: #"{"id":1,"days":[1],"start":"21:00","end":"07:00","action":"cats"}"#)
        let input = Node64.DNS64ScheduleInput(days: [1], start: "21:00", end: "07:00", action: .cats, categories: [.games])
        let created = try await Node64.mock(schedule).dns64.groups.schedules.create(group: 4, input)
        #expect(created.action == .cats)
        #expect(schedule.lastRequest?.nodeRelativePath == "/dns64/groups/4/schedules")
        #expect(schedule.lastRequest?.jsonBody?["label"] == nil)

        let off = MockTransport(status: 204)
        try await Node64.mock(off).dns64.groups.schedules.disable(8)
        #expect(off.lastRequest?.nodeRelativePath == "/dns64/groups/schedules/8/disable")
        try await Node64.mock(off).dns64.groups.members.delete(2)
        #expect(off.lastRequest?.nodeRelativePath == "/dns64/groups/members/2")
        #expect(off.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Devices list and names")
    func devices() async throws {
        let transport = MockTransport(json: #"[{"ip":"10.0.0.2","name":"tv"}]"#)
        let devices = try await Node64.mock(transport).dns64.devices.list()
        #expect(devices.first?.name == "tv")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/devices")
        let names = MockTransport(json: #"[{"name":"a.home.lan","ips":["10.0.0.2"]}]"#)
        _ = try await Node64.mock(names).dns64.devices.names()
        #expect(names.lastRequest?.nodeRelativePath == "/dns64/device-names")
    }

    @Test("Error documents become Node64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 404, json: #"{"error":"Nicht gefunden"}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).dns64.groups.delete(99)
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 404)
        #expect(document.error == "Nicht gefunden")
    }
}

extension JSONDecoder {
    /// A decoder for ISO 8601 dates, like the one used by the client.
    fileprivate static var node64Test: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
