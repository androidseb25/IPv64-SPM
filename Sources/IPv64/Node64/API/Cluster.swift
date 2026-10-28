import Foundation

extension Node64.Cluster {
    /// Members with their state, the forwarding node, the open code and the sync switches.
    ///
    /// `GET /group`
    public func group() async throws -> Node64.ClusterGroup {
        try await client.send(Request(.get, "/group"))
    }

    /// Creates a pairing code for another node (valid for 10 minutes, once).
    ///
    /// Fails with `409` without an ipv64 account.
    ///
    /// `POST /group/code`
    public func createCode() async throws -> Node64.ClusterCode {
        try await client.send(Request(.post, "/group/code"))
    }

    /// Discards the open pairing code.
    ///
    /// `DELETE /group/code`
    public func discardCode() async throws {
        try await client.sendWithoutContent(Request(.delete, "/group/code"))
    }

    /// Joins a group.
    ///
    /// Errors: `403` other ipv64 account, `409` no account or this node itself, `422` code wrong/expired or invalid
    /// input, `502` node unreachable.
    ///
    /// - Parameters:
    ///   - address: Address of a node of the group, `http(s)://…`.
    ///   - code: Pairing code from that node.
    ///   - selfURL: Address of this node for the others; `nil` lets the node decide.
    ///
    /// `POST /group/join`
    public func join(address: String, code: String, selfURL: String? = nil) async throws -> Node64.ClusterGroup {
        try await client.send(Request(.post, "/group/join", body: .json(JoinBody(addr: address, code: code, selfURL: selfURL))))
    }

    /// Leaves the group. The other members are informed.
    ///
    /// `POST /group/leave`
    public func leave() async throws {
        try await client.sendWithoutContent(Request(.post, "/group/leave"))
    }

    /// Changes the address of a member. Fails with `404` for an unknown member.
    ///
    /// - Parameters:
    ///   - id: Node ID of the member.
    ///   - url: New address.
    ///
    /// `PUT /group/members/{id}`
    public func updateMember(_ id: String, url: String) async throws {
        try await client.sendWithoutContent(Request(.put, "/group/members/\(id)", body: .json(MemberBody(url: url))))
    }

    /// Removes a member from the group. Fails with `502` if that failed.
    ///
    /// - Parameter id: Node ID of the member.
    ///
    /// `DELETE /group/members/{id}`
    public func removeMember(_ id: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/group/members/\(id)"))
    }

    /// Resumes a suspended member. The node checks again; if it still does not fit, the member stays suspended.
    ///
    /// Errors: `404` unknown, `409` still does not fit (reason in ``group()``), `502` unreachable or check failed.
    ///
    /// - Parameter id: Node ID of the member.
    ///
    /// `POST /group/members/{id}/resume`
    public func resumeMember(_ id: String) async throws {
        try await client.sendWithoutContent(Request(.post, "/group/members/\(id)/resume"))
    }

    /// Switches the sync of a module or area on or off.
    ///
    /// It only applies if the area is on at both nodes. Errors: `404` unknown module or area,
    /// `422` module or enabled missing.
    ///
    /// - Parameters:
    ///   - module: Module ID, e.g. `certs`.
    ///   - item: Area ID, e.g. `certificates`; `nil` or empty = the module itself.
    ///   - enabled: Switch on or off.
    /// - Returns: The new switches.
    ///
    /// `PUT /group/sync`
    public func setSync(module: String, item: String? = nil, enabled: Bool) async throws -> Node64.ClusterSyncState {
        try await client.send(Request(.put, "/group/sync", body: .json(SyncBody(module: module, item: item, enabled: enabled))))
    }

    private struct JoinBody: Encodable, Sendable {
        let addr: String?
        let code: String?
        let selfURL: String?

        enum CodingKeys: String, CodingKey {
            case addr, code
            case selfURL = "self_url"
        }
    }

    private struct MemberBody: Encodable, Sendable {
        let url: String
    }

    private struct SyncBody: Encodable, Sendable {
        let module: String
        let item: String?
        let enabled: Bool
    }
}
