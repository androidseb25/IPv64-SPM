import Foundation

extension Node64 {
    /// Type of a custom DNS record.
    public struct DNS64RecordType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let a: Self = "A"
        public static let aaaa: Self = "AAAA"
        public static let cname: Self = "CNAME"
        public static let txt: Self = "TXT"
        public static let mx: Self = "MX"
        public static let srv: Self = "SRV"
        public static let ptr: Self = "PTR"
        public static let caa: Self = "CAA"
    }

    /// File format of ``Node64/DNS64/Records/export(format:)``.
    public struct DNS64ExportFormat: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Hosts file (A/AAAA only, default).
        public static let hosts: Self = "hosts"
        /// CSV.
        public static let csv: Self = "csv"
        /// JSON.
        public static let json: Self = "json"
    }

    /// A custom DNS record. Schema `DNS64Record`.
    public struct DNS64Record: Codable, Hashable, Sendable, Identifiable {
        /// Record ID.
        public let id: Int
        /// Name; `*.name` matches all subnames. For PTR also an IP address.
        public let name: String
        /// Record type.
        public let type: DNS64RecordType
        /// IP, target name, text, or `10 mail.home.lan` (MX), `0 5 5060 sip.home.lan` (SRV), `0 issue letsencrypt.org` (CAA).
        public let value: String
        /// Time to live in seconds (default 300).
        public let ttl: Int?
        /// Whether the record is active.
        public let enabled: Bool?
        /// Creation time.
        public let createdAt: Date?
        /// Comment (max. 200 characters).
        public let comment: String?
        /// A/AAAA: no reverse lookup from this record.
        public let noPTR: Bool?
        /// Only this node (never synced in a cluster).
        public let localOnly: Bool?
        /// Created by a dynamic update.
        public let dynamic: Bool?

        enum CodingKeys: String, CodingKey {
            case id, name, type, value, ttl, enabled
            case createdAt = "created_at"
            case comment
            case noPTR = "no_ptr"
            case localOnly = "local_only"
            case dynamic
        }
    }

    /// Writable fields of a custom DNS record for create and update.
    public struct DNS64RecordInput: Encodable, Hashable, Sendable {
        /// Name; `*.name` matches all subnames. For PTR also an IP address.
        public var name: String
        /// Record type.
        public var type: DNS64RecordType
        /// IP, target name, text, or `10 mail.home.lan` (MX), `0 5 5060 sip.home.lan` (SRV), `0 issue letsencrypt.org` (CAA).
        public var value: String
        /// Time to live in seconds (default 300).
        public var ttl: Int?
        /// Comment (max. 200 characters).
        public var comment: String?
        /// A/AAAA: no reverse lookup from this record.
        public var noPTR: Bool?
        /// Only this node (never synced in a cluster).
        public var localOnly: Bool?

        /// Creates a record input; optional fields left `nil` are not sent.
        public init(
            name: String,
            type: DNS64RecordType,
            value: String,
            ttl: Int? = nil,
            comment: String? = nil,
            noPTR: Bool? = nil,
            localOnly: Bool? = nil
        ) {
            self.name = name
            self.type = type
            self.value = value
            self.ttl = ttl
            self.comment = comment
            self.noPTR = noPTR
            self.localOnly = localOnly
        }

        enum CodingKeys: String, CodingKey {
            case name, type, value, ttl, comment
            case noPTR = "no_ptr"
            case localOnly = "local_only"
        }
    }

    /// Result of ``Node64/DNS64/Records/importRecords(_:zone:)``.
    public struct DNS64RecordImportResult: Codable, Hashable, Sendable {
        /// Records added.
        public let added: Int?
        /// Records skipped because they already exist.
        public let skipped: Int?
        /// Entries that could not be parsed.
        public let invalid: Int?
    }
}
