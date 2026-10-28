import Foundation

extension IPv64 {
    /// Offline pages shown during a DNS failover.
    public var offlinePages: OfflinePages { OfflinePages(client: self) }

    /// Endpoints of the *Offline-Pages* area.
    public struct OfflinePages: Sendable {
        let client: IPv64

        /// All offline pages.
        ///
        /// `GET /offline-pages`
        public func list() async throws -> [OfflinePage] {
            try await client.send(Request(.get, "/offline-pages"))
        }

        /// Creates an offline page.
        ///
        /// `POST /offline-pages`
        public func create(_ input: OfflinePageInput = OfflinePageInput()) async throws -> OfflinePage {
            try await client.send(Request(.post, "/offline-pages", body: .json(input)))
        }

        /// A single offline page.
        ///
        /// `GET /offline-pages/{id}`
        public func get(_ id: String) async throws -> OfflinePage {
            try await client.send(Request(.get, "/offline-pages/\(id)"))
        }

        /// Changes an offline page. Only non-`nil` fields are changed.
        ///
        /// `PATCH /offline-pages/{id}`
        public func update(_ id: String, _ input: OfflinePageInput) async throws -> OfflinePage {
            try await client.send(Request(.patch, "/offline-pages/\(id)", body: .json(input)))
        }

        /// Deletes an offline page. Not possible while a failover rule uses it.
        ///
        /// `DELETE /offline-pages/{id}`
        public func delete(_ id: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/offline-pages/\(id)"))
        }

        /// Uploads the logo as `multipart/form-data` field `icon`.
        /// JPEG, PNG or WebP, at most 1 MB and 1024 x 1024 pixels.
        ///
        /// - Parameters:
        ///   - id: Offline page ID.
        ///   - imageData: Image bytes.
        ///   - filename: File name, e.g. `logo.png`.
        ///   - contentType: MIME type, e.g. `image/png`.
        ///
        /// `POST /offline-pages/{id}/icon`
        public func uploadIcon(
            _ id: String,
            imageData: Data,
            filename: String,
            contentType: String
        ) async throws -> OfflinePage {
            var form = MultipartFormData()
            form.append(imageData, name: "icon", filename: filename, contentType: contentType)
            return try await client.send(Request(.post, "/offline-pages/\(id)/icon", body: .multipart(form)))
        }

        /// Deletes the logo.
        ///
        /// `DELETE /offline-pages/{id}/icon`
        public func deleteIcon(_ id: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/offline-pages/\(id)/icon"))
        }
    }
}
