import Foundation

extension IPv64 {
    /// Manage notification integrations.
    public var integrations: Integrations { Integrations(client: self) }

    /// Endpoints of the *Benachrichtigungen* (notifications) area.
    public struct Integrations: Sendable {
        let client: IPv64

        /// Lists all integrations.
        ///
        /// `GET /integrations`
        /// - Parameter includeSecrets: Show tokens and URLs in full.
        public func list(includeSecrets: Bool? = nil) async throws -> [Integration] {
            try await client.send(Request(.get, "/integrations", query: [QueryItem("include_secrets", includeSecrets)]))
        }

        /// Creates an integration. The required fields depend on the type, see ``IntegrationInput``.
        ///
        /// Email and SMS integrations send a confirmation link; these are limited to a few per hour.
        ///
        /// `POST /integrations`
        public func create(_ input: IntegrationInput) async throws -> Integration {
            try await client.send(Request(.post, "/integrations", body: .json(input)))
        }

        /// A single integration.
        ///
        /// `GET /integrations/{id}`
        /// - Parameters:
        ///   - id: Integration ID.
        ///   - includeSecrets: Show tokens and URLs in full.
        public func get(_ id: Int, includeSecrets: Bool? = nil) async throws -> Integration {
            try await client.send(Request(
                .get,
                "/integrations/\(id)",
                query: [QueryItem("include_secrets", includeSecrets)]
            ))
        }

        /// Changes the name or the preselection. For other changes, create the integration anew.
        ///
        /// `PATCH /integrations/{id}`
        /// - Parameters:
        ///   - id: Integration ID.
        ///   - name: New name.
        ///   - isDefault: Preselect for new healthchecks.
        public func update(_ id: Int, name: String? = nil, isDefault: Bool? = nil) async throws -> Integration {
            try await client.send(Request(
                .patch,
                "/integrations/\(id)",
                body: .json(UpdateBody(name: name, isDefault: isDefault))
            ))
        }

        /// Deletes an integration.
        ///
        /// `DELETE /integrations/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/integrations/\(id)"))
        }

        /// Sends a test message. ID 0 sends it to the account email. At most one per 30 seconds and integration.
        ///
        /// `POST /integrations/{id}/test`
        @discardableResult
        public func sendTest(_ id: Int) async throws -> IntegrationTestResult {
            try await client.send(Request(.post, "/integrations/\(id)/test"))
        }

        private struct UpdateBody: Encodable, Sendable {
            let name: String?
            let isDefault: Bool?

            enum CodingKeys: String, CodingKey {
                case name
                case isDefault = "default"
            }
        }
    }
}
