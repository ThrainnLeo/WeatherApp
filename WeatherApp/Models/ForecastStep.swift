import Foundation

/// The forecast for one point in time.
nonisolated struct ForecastStep: Codable, Equatable, Sendable {
    /// The moment the values apply to.
    let time: Date
    /// Start of the period that `precipitation` covers. SMHI's steps are 1 hour apart at
    /// first and up to 12 hours apart later, so the amount is only meaningful with its interval.
    let intervalStart: Date

    /// Air temperature in °C.
    let temperature: Double
    let condition: WeatherCondition

    /// Wind speed in m/s.
    let windSpeed: Double?
    /// Strongest gust in m/s.
    let windGust: Double?
    /// Direction the wind comes from, in degrees (0 = north, 90 = east).
    let windDirection: Double?
    /// Precipitation in mm between `intervalStart` and `time`.
    let precipitation: Double?
    /// Chance of at least 0.1 mm precipitation, in percent.
    let precipitationProbability: Double?
    /// Relative humidity in percent.
    let humidity: Double?
}
