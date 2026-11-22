import Foundation

/// What the screen needs once a forecast has arrived.
struct ForecastDisplay: Equatable {
    /// What the forecast is for: the place name, or the coordinates in coordinate mode.
    let title: String
    let grouped: GroupedForecast
    let fetchedAt: Date
    /// Set when cached data is shown because the network failed, e.g.
    /// "Offline – showing data from 14:15." `nil` for fresh data.
    let staleMessage: String?
}
