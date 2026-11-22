import Foundation

/// A forecast arranged the way the screens show it (W-07).
///
/// Not cached: it depends on the current time, so it is rebuilt from `Forecast` each time.
nonisolated struct GroupedForecast: Equatable, Sendable {
    /// The forecast for the current hour, or `nil` if the data has no steps left (very old cache).
    let current: ForecastStep?
    /// Hourly steps from the current hour until local midnight. Can be empty late in the evening.
    let today: [ForecastStep]
    /// One summary per day for the days after today, at most `ForecastGrouper.dayCount`.
    let days: [DailyForecast]
}
