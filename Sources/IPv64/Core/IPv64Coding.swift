import Foundation

/// JSON coding shared by all requests and responses.
///
/// Timestamps are ISO 8601 with time zone, e.g. `2026-10-10T12:00:00+02:00`.
/// Model types map snake_case keys with explicit `CodingKeys`, so no key
/// strategy is applied (it would also rewrite dictionary keys).
enum IPv64Coding {
    private static let internetDateTime = Date.ISO8601FormatStyle()
    private static let internetDateTimeFractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let fullDate = Date.ISO8601FormatStyle().year().month().day()

    static func date(from string: String) -> Date? {
        (try? internetDateTime.parse(string))
            ?? (try? internetDateTimeFractional.parse(string))
            ?? (try? fullDate.parse(string))
    }

    static func string(from date: Date) -> String {
        internetDateTime.format(date)
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = date(from: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected an ISO 8601 timestamp, got '\(string)'."
                )
            }
            return date
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(string(from: date))
        }
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
