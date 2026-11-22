import Foundation

/// A summary of one calendar day (in the user's time zone), built by `ForecastGrouper`.
nonisolated struct DailyForecast: Equatable, Sendable, Identifiable {
    /// Local midnight at the start of the day.
    let date: Date
    /// In °C, over the day's steps. Later days only have 2–4 steps, so these are approximate.
    let minTemperature: Double
    let maxTemperature: Double
    /// The condition of the step closest to 12:00 local time.
    let condition: WeatherCondition
    /// Total precipitation in mm, or `nil` if no step reported any.
    let precipitation: Double?
    /// Highest wind speed in m/s, or `nil` if no step reported any.
    let maxWindSpeed: Double?
    /// The day's individual steps, for the detail screen (W-02).
    let steps: [ForecastStep]

    var id: Date { date }
}
