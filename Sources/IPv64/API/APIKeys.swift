import Foundation

extension IPv64 {
    /// Manage the API keys of the account.
    public var apiKeys: APIKeys { APIKeys(client: self) }

    /// Endpoints of the *API-Keys* area.
    public struct APIKeys: Sendable {
        let client: IPv64

        /// Lists all API keys. The keys themselves are never shown again, only their start and end.
        ///
        /// `GET /api-keys`
        public func list() async throws -> [APIKey] {
            try await client.send(Request(.get, "/api-keys"))
        }

        /// Creates an API key. The full key is only contained in this response.
        ///
        /// `POST /api-keys`
        /// - Parameters:
        ///   - name: Name of the key.
        ///   - expiresIn: Validity in seconds (0 to 315360000); 0 means unlimited.
        public func create(name: String? = nil, expiresIn: Int? = nil) async throws -> APIKeyCreated {
            try await client.send(Request(.post, "/api-keys", body: .json(CreateBody(name: name, expiresIn: expiresIn))))
        }

        /// Deletes an API key. The key you are currently signed in with cannot delete itself.
        ///
        /// `DELETE /api-keys/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/api-keys/\(id)"))
        }

        private struct CreateBody: Encodable, Sendable {
            let name: String?
            let expiresIn: Int?

            enum CodingKeys: String, CodingKey {
                case name
                case expiresIn = "expires_in"
            }
        }
    }
}
