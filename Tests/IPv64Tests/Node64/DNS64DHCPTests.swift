import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DNS64 DHCP")
struct Node64DNS64DHCPTests {
    private let scopeJSON = """
    {"id":3,"name":"Heimnetz","interface":"eth0","subnet":"192.168.1.0/24","range_start":"192.168.1.100",
     "range_end":"192.168.1.199","router":"192.168.1.1","dns":[],"domain":"home.lan","lease_hours":24,
     "ntp":["pool.ntp.org"],"authoritative":true,"boot_server":"10.0.0.2","boot_bios":"a.kpxe","boot_uefi":"a.efi",
     "boot_ipxe":"a.ipxe","relay":false,"enabled":true,"created_at":"2026-11-01T08:00:00Z"}
    """
    private let reservationJSON = """
    {"id":5,"scope_id":3,"mac":"aa:bb:cc:dd:ee:ff","ip":"192.168.1.20","name":"nas","comment":"NAS","group_id":2}
    """
    private let routerJSON = """
    {"interface":"eth0","source":"fe80::1","router_lifetime":1800,"managed":true,"other":false,
     "prefixes":[{"prefix":"2001:db8::/64","slaac":true,"on_link":true,"valid_lifetime":86400}],
     "dns":["2001:db8::53"],"domains":["home.lan"],"last_seen":"2026-11-11T10:00:00Z"}
    """

    @Test("status returns raw JSON")
    func status() async throws {
        let transport = MockTransport(json: #"{"mode":"observe","role":"primary","running":true}"#)
        let result = try await Node64.mock(transport).dns64.dhcp.status()
        #expect(result["mode"]?.stringValue == "observe")
        #expect(transport.lastRequest?.httpMethod == "GET")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp")
    }

    @Test("mode and role send their body and accept an empty answer")
    func modeRole() async throws {
        let transport = MockTransport(status: 200)
        let node = Node64.mock(transport)
        try await node.dns64.dhcp.setMode(.observe)
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/mode")
        #expect(transport.lastRequest?.jsonBody == .object(["mode": .string("observe")]))
        try await node.dns64.dhcp.setRole(.reserve)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/role")
        #expect(transport.lastRequest?.jsonBody == .object(["role": .string("reserve")]))
    }

    @Test("release lease path")
    func releaseLease() async throws {
        let transport = MockTransport(status: 204, json: "")
        try await Node64.mock(transport).dns64.dhcp.releaseLease(scope: 3, mac: "aa:bb:cc:dd:ee:ff")
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/leases/3/aa:bb:cc:dd:ee:ff")
    }

    @Test("ipv6 state decodes")
    func ipv6() async throws {
        let json = """
        {"config":{"enabled":true,"interfaces":["eth0"],"domain":"home.lan"},"running":true,"error":"x",
         "status":[{"interface":"eth0","dns":["fd00::1"],"last_sent":"2026-11-11T10:00:00Z","error":"e","error_kind":"no_addr"}],
         "routers":[\(routerJSON)]}
        """
        let transport = MockTransport(json: json)
        let state = try await Node64.mock(transport).dns64.dhcp.ipv6()
        #expect(state.config?.interfaces == ["eth0"])
        #expect(state.status?.first?.errorKind == .noAddress)
        #expect(state.status?.first?.lastSent != nil)
        let router = try #require(state.routers?.first)
        #expect(router.routerLifetime == 1800)
        #expect(router.prefixes?.first?.onLink == true)
        #expect(router.lastSeen != nil)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/ipv6")
    }

    @Test("ipv6 update sends only set fields")
    func updateIPv6() async throws {
        let transport = MockTransport(json: "{}")
        try await Node64.mock(transport).dns64.dhcp.updateIPv6(.init(enabled: true, interfaces: ["eth0"]))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/ipv6")
        #expect(transport.lastRequest?.jsonBody == .object(["enabled": .bool(true), "interfaces": .array([.string("eth0")])]))
    }

    @Test("probe decodes routers")
    func probe() async throws {
        let transport = MockTransport(json: #"{"routers":[\#(routerJSON)]}"#)
        let result = try await Node64.mock(transport).dns64.dhcp.probeIPv6()
        #expect(result.routers?.first?.source == "fe80::1")
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/ipv6/probe")
    }

    @Test("scopes list, create, update")
    func scopes() async throws {
        let list = MockTransport(json: "[\(scopeJSON)]")
        let scope = try #require(try await Node64.mock(list).dns64.dhcp.scopes.list().first)
        #expect(scope.id == 3)
        #expect(scope.rangeStart == "192.168.1.100")
        #expect(scope.leaseHours == 24)
        #expect(scope.bootIPXE == "a.ipxe")
        #expect(scope.enabled == true)
        #expect(scope.createdAt != nil)
        #expect(list.lastRequest?.nodeRelativePath == "/dns64/dhcp/scopes")

        let input = Node64.DNS64DHCPScopeInput(
            interface: "eth0", subnet: "192.168.1.0/24", rangeStart: "192.168.1.100", rangeEnd: "192.168.1.199", leaseHours: 12
        )
        let create = MockTransport(status: 201, json: scopeJSON)
        _ = try await Node64.mock(create).dns64.dhcp.scopes.create(input)
        #expect(create.lastRequest?.httpMethod == "POST")
        #expect(create.lastRequest?.nodeRelativePath == "/dns64/dhcp/scopes")
        #expect(create.lastRequest?.jsonBody == .object([
            "interface": .string("eth0"), "subnet": .string("192.168.1.0/24"),
            "range_start": .string("192.168.1.100"), "range_end": .string("192.168.1.199"), "lease_hours": .number(12),
        ]))

        let update = MockTransport(json: scopeJSON)
        _ = try await Node64.mock(update).dns64.dhcp.scopes.update(3, input)
        #expect(update.lastRequest?.httpMethod == "PUT")
        #expect(update.lastRequest?.nodeRelativePath == "/dns64/dhcp/scopes/3")
    }

    @Test("scope delete, enable, disable")
    func scopeActions() async throws {
        let transport = MockTransport(status: 204, json: "")
        let scopes = Node64.mock(transport).dns64.dhcp.scopes
        try await scopes.delete(3)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/scopes/3")
        try await scopes.enable(3)
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/scopes/3/enable")
        try await scopes.disable(3)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/dhcp/scopes/3/disable")
    }

    @Test("reservations list, create, update, delete")
    func reservations() async throws {
        let list = MockTransport(json: "[\(reservationJSON)]")
        let reservation = try #require(try await Node64.mock(list).dns64.dhcp.reservations.list().first)
        #expect(reservation.scopeID == 3)
        #expect(reservation.mac == "aa:bb:cc:dd:ee:ff")
        #expect(reservation.groupID == 2)
        #expect(list.lastRequest?.nodeRelativePath == "/dns64/dhcp/reservations")

        let input = Node64.DNS64DHCPReservationInput(scopeID: 3, mac: "aa:bb:cc:dd:ee:ff", ip: "192.168.1.20", name: "nas", groupID: 2)
        let create = MockTransport(status: 201, json: reservationJSON)
        _ = try await Node64.mock(create).dns64.dhcp.reservations.create(input)
        #expect(create.lastRequest?.httpMethod == "POST")
        #expect(create.lastRequest?.jsonBody == .object([
            "scope_id": .number(3), "mac": .string("aa:bb:cc:dd:ee:ff"), "ip": .string("192.168.1.20"),
            "name": .string("nas"), "group_id": .number(2),
        ]))

        let update = MockTransport(json: reservationJSON)
        _ = try await Node64.mock(update).dns64.dhcp.reservations.update(5, input)
        #expect(update.lastRequest?.httpMethod == "PUT")
        #expect(update.lastRequest?.nodeRelativePath == "/dns64/dhcp/reservations/5")

        let delete = MockTransport(status: 204, json: "")
        try await Node64.mock(delete).dns64.dhcp.reservations.delete(5)
        #expect(delete.lastRequest?.httpMethod == "DELETE")
        #expect(delete.lastRequest?.nodeRelativePath == "/dns64/dhcp/reservations/5")
    }
}
