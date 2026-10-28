import Foundation

/// A string-backed value with a set of known cases that stays decodable when
/// the server introduces new values.
///
/// Conforming types are structs with static constants for the documented
/// values, so `switch` statements need a `default` branch and new server
/// values never break decoding:
///
/// ```swift
/// public struct DomainKind: IPv64OpenEnum {
///     public let rawValue: String
///     public init(rawValue: String) { self.rawValue = rawValue }
///
///     public static let dyndns: Self = "dyndns"
///     public static let own: Self = "own"
/// }
/// ```
public protocol IPv64OpenEnum:
    RawRepresentable,
    Codable,
    Hashable,
    Sendable,
    ExpressibleByStringLiteral,
    CustomStringConvertible
where RawValue == String {
    init(rawValue: String)
}

extension IPv64OpenEnum {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String { rawValue }
}
