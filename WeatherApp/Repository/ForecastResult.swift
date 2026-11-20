import Foundation

/// What the repository hands to the ViewModel: a forecast and where it came from.
nonisolated struct ForecastResult: Equatable, Sendable {
    let forecast: Forecast
    /// When the forecast was downloaded (now for fresh data, earlier for cached data).
    let fetchedAt: Date
    /// `nil` if the forecast is fresh from the network. Otherwise the network failed with
    /// this error and cached data is shown instead, so the UI can explain why (W-10).
    let staleReason: WeatherError?

    var isStale: Bool { staleReason != nil }
}
