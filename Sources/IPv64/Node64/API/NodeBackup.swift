import Foundation

extension Node64.Node {
    /// Downloads only the database as an SQLite file, without the keys of the node.
    ///
    /// This backup does not work on a new node because the secret key is missing.
    /// Use ``createBackup(password:includeStatistics:)`` for a complete backup.
    ///
    /// `GET /backup`
    public func downloadDatabase() async throws -> Data {
        try await client.sendData(Request(.get, "/backup"), accept: "application/vnd.sqlite3")
    }

    /// Creates a complete backup as an encrypted archive (`.n64backup`).
    ///
    /// It contains the database, the secret key of the node (`secret.key`), DNS64 shares and certificate files;
    /// with `includeStatistics` also the DNS64 query log and PROXY64 statistics.
    /// Encrypted with XChaCha20-Poly1305, the key is derived from the password with Argon2id.
    /// Fails with `422` if the password is shorter than 8 characters. The archive contains secrets, so protect it.
    ///
    /// - Parameters:
    ///   - password: Password of the archive, at least 8 characters.
    ///   - includeStatistics: Also include the DNS64 query log and PROXY64 statistics (server default `false`).
    ///
    /// `POST /backup`
    public func createBackup(password: String, includeStatistics: Bool? = nil) async throws -> Data {
        let body = BackupBody(password: password, stats: includeStatistics)
        return try await client.sendData(
            Request(.post, "/backup", body: .json(body)),
            accept: "application/octet-stream"
        )
    }

    /// Restores a backup from raw bytes. **Destructive: the node replaces its data and restarts.**
    ///
    /// The body is an archive (`.n64backup`) or a database, at most 1 GB; the file is validated first.
    /// What is replaced is kept under `/data/backups`. Errors: `422` not a valid Node64 database,
    /// `401` the archive needs a password, `403` the password does not match.
    ///
    /// - Parameters:
    ///   - backup: Archive or database bytes.
    ///   - password: Password of the archive (header `X-Backup-Password`).
    ///
    /// `POST /backup/restore`
    @discardableResult
    public func restoreBackup(_ backup: Data, password: String? = nil) async throws -> Node64.BackupRestoreResult {
        let headers = password.map { ["X-Backup-Password": $0] } ?? [:]
        return try await client.send(Request(
            .post, "/backup/restore",
            body: .raw(backup, contentType: "application/octet-stream"),
            headers: headers
        ))
    }

    /// Restores a backup from a multipart upload. **Destructive: the node replaces its data and restarts.**
    ///
    /// Same as ``restoreBackup(_:password:)``, but sends the file as the multipart field `file` and the
    /// password as the multipart field `password`.
    ///
    /// `POST /backup/restore`
    @discardableResult
    public func restoreBackup(
        file: Data,
        filename: String = "backup.n64backup",
        password: String? = nil
    ) async throws -> Node64.BackupRestoreResult {
        var form = MultipartFormData()
        form.append(file, name: "file", filename: filename, contentType: "application/octet-stream")
        if let password { form.append(password, name: "password") }
        return try await client.send(Request(.post, "/backup/restore", body: .multipart(form)))
    }

    /// Exports the configuration (settings, channels, modules) as a file for ``importConfiguration(_:password:)``.
    ///
    /// - Parameters:
    ///   - secrets: With ``Node64/NodeExportSecrets/password`` secrets are included, encrypted; default: they are missing.
    ///   - password: Password for the secrets, at least 8 characters. Fails with `422` if too short.
    ///
    /// `POST /export`
    public func exportConfiguration(
        secrets: Node64.NodeExportSecrets? = nil,
        password: String? = nil
    ) async throws -> JSONValue {
        try await client.sendJSON(Request(.post, "/export", body: .json(ExportBody(secrets: secrets, password: password))))
    }

    /// Imports a configuration created by ``exportConfiguration(secrets:password:)``.
    /// **Destructive: it overwrites existing configuration.**
    ///
    /// With a wrong password nothing is imported. Fails with `422` if it is not a Node64 configuration
    /// or the password is missing or wrong.
    ///
    /// - Parameters:
    ///   - configuration: The exported file.
    ///   - password: Password for encrypted secrets (header `X-Config-Password`).
    ///
    /// `POST /import`
    @discardableResult
    public func importConfiguration(_ configuration: JSONValue, password: String? = nil) async throws -> Node64.NodeImportResult {
        let headers = password.map { ["X-Config-Password": $0] } ?? [:]
        return try await client.send(Request(.post, "/import", body: .json(configuration), headers: headers))
    }

    /// Imports a configuration from the bytes of an exported file. **Destructive: it overwrites existing configuration.**
    ///
    /// `POST /import`
    @discardableResult
    public func importConfiguration(_ configuration: Data, password: String? = nil) async throws -> Node64.NodeImportResult {
        let headers = password.map { ["X-Config-Password": $0] } ?? [:]
        return try await client.send(Request(
            .post, "/import",
            body: .raw(configuration, contentType: "application/json"),
            headers: headers
        ))
    }

    /// Factory reset. **Destructive and irreversible: the node restarts and empties its data directory.**
    ///
    /// Requires the password of the user, also with an API key. Before that the node signs off online
    /// (ipv64 link, CDN64 names and tunnel, local group); what fails is listed in
    /// ``Node64/NodeResetResult/cleanupProblems`` and the reset runs anyway.
    /// Fails with `403` for a wrong password.
    ///
    /// - Parameters:
    ///   - password: Password of the user.
    ///   - keepChecks: If linked, keep the checks at ipv64.
    ///
    /// `POST /reset`
    @discardableResult
    public func reset(password: String, keepChecks: Bool? = nil) async throws -> Node64.NodeResetResult {
        try await client.send(Request(.post, "/reset", body: .json(ResetBody(password: password, keepChecks: keepChecks))))
    }

    private struct BackupBody: Encodable, Sendable {
        let password: String
        let stats: Bool?
    }

    private struct ExportBody: Encodable, Sendable {
        let secrets: Node64.NodeExportSecrets?
        let password: String?
    }

    private struct ResetBody: Encodable, Sendable {
        let password: String
        let keepChecks: Bool?

        enum CodingKeys: String, CodingKey {
            case password
            case keepChecks = "keep_checks"
        }
    }
}
