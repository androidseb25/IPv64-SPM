import Foundation

extension Node64.Monitor64 {
    /// Hosts with their services and traps.
    public var hosts: Hosts { Hosts(client: client) }
    /// Accesses (agent, SSH, Proxmox, Docker, SNMP, ...) of hosts.
    public var access: Access { Access(client: client) }
    /// Agent distribution.
    public var agent: Agent { Agent(client: client) }
    /// SNMP trap receiver.
    public var traps: Traps { Traps(client: client) }

    /// Host endpoints of Monitor64.
    public struct Hosts: Sendable { let client: Node64 }
    /// Access endpoints of Monitor64. Secrets of accesses are write-only and never returned.
    public struct Access: Sendable { let client: Node64 }
    /// Agent distribution endpoints of Monitor64.
    public struct Agent: Sendable { let client: Node64 }
    /// SNMP trap receiver endpoints of Monitor64.
    public struct Traps: Sendable { let client: Node64 }

    /// Tests a connection once before anything is saved (wizard) and returns the discovered services.
    ///
    /// With `accessUID` a stored access is tested with the changes from `input.access`; the stored secret only goes to the
    /// stored target (a changed URL or pin gives a result with a "save first" warning). Time limit 20 s. A failed test is
    /// still `200` with `ok == false`. Errors: `400` for invalid access fields, `404` unknown access.
    ///
    /// `POST /monitor64/test`
    public func test(_ input: Node64.Monitor64TestInput) async throws -> Node64.Monitor64TestResult {
        try await client.send(Request(.post, "/monitor64/test", body: .json(input)))
    }

    /// Source address of this node towards a target (for `from="..."` in `authorized_keys`). No packet is sent.
    ///
    /// - Parameter target: Hostname or IP of the host.
    /// - Returns: The address, empty if unknown.
    ///
    /// `GET /monitor64/nodeaddr`
    public func nodeAddress(target: String? = nil) async throws -> String {
        try await client.send(Request(.get, "/monitor64/nodeaddr", query: [QueryItem("target", target)]), as: NodeAddress.self).addr
    }

    /// A new push token for the install command of the wizard (stored only together with the access; gives no access)
    /// and the push port of the node.
    ///
    /// `GET /monitor64/push/token`
    public func pushToken() async throws -> Node64.Monitor64PushToken {
        try await client.send(Request(.get, "/monitor64/push/token"))
    }

    struct NodeAddress: Decodable, Sendable { let addr: String }
}

extension Node64.Monitor64.Hosts {
    /// All hosts with their current state (as on the overview).
    ///
    /// `GET /monitor64/hosts`
    public func list() async throws -> [Node64.Monitor64OverviewHost] {
        try await client.send(Request(.get, "/monitor64/hosts"))
    }

    /// A host with services, thresholds per service, accesses (without secrets, with runtime state), new and ignored
    /// services and the charts of the host page. Fails with `404` (`not_found`) if unknown.
    ///
    /// `GET /monitor64/hosts/{uid}`
    public func get(_ uid: String) async throws -> Node64.Monitor64HostDetail {
        try await client.send(Request(.get, "/monitor64/hosts/\(uid)"))
    }

    /// Creates a host with up to 8 accesses. Discovered services from the connection test are entered as new, those in
    /// `adopt` are adopted at once. The first query starts immediately. Access secrets in the input are write-only.
    ///
    /// - Returns: The UID of the new host.
    ///
    /// `POST /monitor64/hosts`
    public func create(_ input: Node64.Monitor64HostCreate) async throws -> Node64.Monitor64HostUID {
        try await client.send(Request(.post, "/monitor64/hosts", body: .json(input)))
    }

    /// Replaces the fields of a host (`PUT`). Only `kind`, `intervalSec` and `agentAutoupdate` stay unchanged when empty,
    /// 0 or `nil`; everything else, including `tags`, `group` and `notes`, is replaced. Pausing and resuming is logged.
    ///
    /// `PUT /monitor64/hosts/{uid}`
    public func update(_ uid: String, _ input: Node64.Monitor64HostInput) async throws -> Node64.Monitor64HostUID {
        try await client.send(Request(.put, "/monitor64/hosts/\(uid)", body: .json(input)))
    }

    /// Removes a host with its accesses and closes its open problems (the problem history stays).
    ///
    /// - Parameter deleteHistory: Also delete the measurement history (`history=delete`, cannot be undone).
    ///
    /// `DELETE /monitor64/hosts/{uid}`
    @discardableResult
    public func delete(_ uid: String, deleteHistory: Bool = false) async throws -> Node64.Monitor64HostDeleted {
        try await client.send(Request(.delete, "/monitor64/hosts/\(uid)", query: [QueryItem("history", deleteHistory ? "delete" : nil)]))
    }

    /// Creates an access on the host; it is queried at once. The secret in `input` is write-only.
    ///
    /// `POST /monitor64/hosts/{uid}/access`
    public func createAccess(host uid: String, _ input: Node64.Monitor64AccessInput) async throws -> Node64.Monitor64Access {
        try await client.send(Request(.post, "/monitor64/hosts/\(uid)/access", body: .json(input)))
    }

    /// Runs a discovery round now (time limit 20 s) and reports the result. Fails with `503` (`not_running`) if the host
    /// is not scheduled on this node or the module does not run.
    ///
    /// `POST /monitor64/hosts/{uid}/discover`
    public func discover(_ uid: String) async throws -> Node64.Monitor64DiscoverResult {
        try await client.send(Request(.post, "/monitor64/hosts/\(uid)/discover"))
    }

    /// Adopts, ignores or offers again discovered services. Unknown keys are skipped.
    ///
    /// - Parameters:
    ///   - keys: Service keys (1 to 5000).
    ///   - state: What to do with them.
    ///
    /// `POST /monitor64/hosts/{uid}/services/adopt`
    public func adoptServices(host uid: String, keys: [String], state: Node64.Monitor64AdoptState) async throws -> Node64.Monitor64ServicesChanged {
        try await client.send(Request(.post, "/monitor64/hosts/\(uid)/services/adopt", body: .json(ServicesBody(keys: keys, state: state))))
    }

    /// Removes services (e.g. after "vanished"). Unknown keys are skipped.
    ///
    /// - Parameter keys: Service keys (1 to 5000).
    ///
    /// `POST /monitor64/hosts/{uid}/services/remove`
    public func removeServices(host uid: String, keys: [String]) async throws -> Node64.Monitor64ServicesChanged {
        try await client.send(Request(.post, "/monitor64/hosts/\(uid)/services/remove", body: .json(ServicesBody(keys: keys, state: nil))))
    }

    /// Changes a service: display name, wanted state, "display only" and the thresholds of the level "this host" per rule
    /// kind. Missing or `nil` fields stay unchanged. The effective threshold including inherited fields is validated
    /// (warning before critical). Fails with `404` for an unknown host or service.
    ///
    /// `PUT /monitor64/hosts/{uid}/service`
    @discardableResult
    public func updateService(host uid: String, _ update: Node64.Monitor64ServiceUpdate) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.put, "/monitor64/hosts/\(uid)/service", body: .json(update)))
    }

    /// Latest traps of a host, newest first (in a cluster the state of the responsible node).
    ///
    /// `GET /monitor64/hosts/{uid}/traps`
    public func traps(_ uid: String) async throws -> Node64.Monitor64HostTraps {
        try await client.send(Request(.get, "/monitor64/hosts/\(uid)/traps"))
    }

    /// Resets the open traps of a host (like acknowledging the problem on the service "traps").
    ///
    /// `POST /monitor64/hosts/{uid}/traps/reset`
    @discardableResult
    public func resetTraps(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.post, "/monitor64/hosts/\(uid)/traps/reset"))
    }

    /// Switches automatic agent updates of a host on or off.
    ///
    /// `PUT /monitor64/hosts/{uid}/agent`
    public func updateAgent(host uid: String, autoupdate: Bool) async throws -> Node64.Monitor64AgentAutoupdate {
        try await client.send(Request(.put, "/monitor64/hosts/\(uid)/agent", body: .json(AutoupdateBody(autoupdate: autoupdate))))
    }

    /// Updates the agent of a host now, even with automatic updates off. The update runs in the background (`202`); read
    /// the result with ``Node64/Monitor64/Agent/get()`` or at the access. Errors: `400` with `agent_elsewhere`,
    /// `agent_no_index`, `agent_busy`, `agent_no_file`, `agent_none` or `agent_current`; `503` if the module does not run.
    ///
    /// `POST /monitor64/hosts/{uid}/agent/update`
    public func updateAgentNow(host uid: String) async throws -> Node64.Monitor64AgentUpdateStarted {
        try await client.send(Request(.post, "/monitor64/hosts/\(uid)/agent/update"))
    }

    struct ServicesBody: Encodable, Sendable {
        let keys: [String]
        let state: Node64.Monitor64AdoptState?
    }

    struct AutoupdateBody: Encodable, Sendable { let autoupdate: Bool }
}

extension Node64.Monitor64.Access {
    /// Changes an access (`PUT`). Empty fields stay: an empty `secret` keeps the stored one, `clearSecret` removes it, a
    /// `nil` `config` keeps the configuration (it is checked again). `hostkey: "reset"` discards the remembered SSH host
    /// key. The secret is write-only and never returned.
    ///
    /// `PUT /monitor64/access/{uid}`
    public func update(_ uid: String, _ input: Node64.Monitor64AccessInput) async throws -> Node64.Monitor64Access {
        try await client.send(Request(.put, "/monitor64/access/\(uid)", body: .json(input)))
    }

    /// Removes an access.
    ///
    /// `DELETE /monitor64/access/{uid}`
    @discardableResult
    public func delete(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.delete, "/monitor64/access/\(uid)"))
    }

    /// Discards the remembered SSH host key; the next contact remembers the new one (after "key changed").
    ///
    /// `POST /monitor64/access/{uid}/hostkey-reset`
    @discardableResult
    public func resetHostKey(_ uid: String) async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.post, "/monitor64/access/\(uid)/hostkey-reset"))
    }

    /// Tests a stored access with its stored secret and host key; nothing is saved.
    ///
    /// - Parameter changes: Optional form changes (as for `PUT`, without changing the type); an empty or partly new secret
    ///   is merged with the stored one. `nil` tests the stored state. The stored secret only goes to the stored target.
    ///
    /// `POST /monitor64/access/{uid}/test`
    public func test(_ uid: String, changes: Node64.Monitor64AccessInput? = nil) async throws -> Node64.Monitor64TestResult {
        try await client.send(Request(.post, "/monitor64/access/\(uid)/test", body: changes.map { .json($0) }))
    }
}

extension Node64.Monitor64.Agent {
    /// State of the agent distribution: available version, files, install commands and hosts with their agent version
    /// (no network access).
    ///
    /// `GET /monitor64/agent`
    public func get() async throws -> Node64.Monitor64Agent {
        try await client.send(Request(.get, "/monitor64/agent"))
    }

    /// Fetches the agent directory now ("check now"); an error is afterwards in `source.error`. Fails with `503` if the
    /// module does not run.
    ///
    /// `POST /monitor64/agent/refresh`
    public func refresh() async throws -> Node64.Monitor64Agent {
        try await client.send(Request(.post, "/monitor64/agent/refresh"))
    }
}

extension Node64.Monitor64.Traps {
    /// State of the SNMP trap receiver with counters and unknown senders.
    ///
    /// `GET /monitor64/traps`
    public func status() async throws -> Node64.Monitor64TrapStatus {
        try await client.send(Request(.get, "/monitor64/traps"))
    }

    /// Clears the list of unknown trap senders.
    ///
    /// `DELETE /monitor64/traps/unknown`
    @discardableResult
    public func clearUnknown() async throws -> Node64.Monitor64Ok {
        try await client.send(Request(.delete, "/monitor64/traps/unknown"))
    }
}
