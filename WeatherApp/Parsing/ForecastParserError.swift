import Foundation

/// Why `ForecastParser` could not produce a forecast.
/// The repository later maps these to the app-wide `WeatherError.decoding`.
nonisolated enum ForecastParserError: Error, Equatable, Sendable {
    /// The body is not JSON in SMHI's format (for example an HTML error page,
    /// or JSON with a required field missing).
    case invalidJSON
    /// The JSON was valid, but no time step had both a temperature and a weather symbol.
    case noUsableTimeSteps
}
