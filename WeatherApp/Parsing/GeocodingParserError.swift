import Foundation

/// Why `GeocodingParser` could not read a response. Mapped to `WeatherError.decoding`.
nonisolated enum GeocodingParserError: Error, Equatable, Sendable {
    /// Not a JSON array of places (for example an HTML error page).
    case invalidJSON
}
