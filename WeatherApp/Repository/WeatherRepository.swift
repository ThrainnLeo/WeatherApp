import Foundation

/// The ViewModel's single entry point for forecasts: fetch → parse → cache → fallback.
nonisolated struct WeatherRepository: Sendable {
    private let apiClient: any WeatherAPIClient
    private let parser: ForecastParser
    private let cache: any CacheStore
    /// Injected so tests can control `fetchedAt` instead of depending on the real clock.
    private let now: @Sendable () -> Date

    init(
        apiClient: any WeatherAPIClient,
        parser: ForecastParser = ForecastParser(),
        cache: any CacheStore,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiClient = apiClient
        self.parser = parser
        self.cache = cache
        self.now = now
    }

    /// `@concurrent` moves this work off the main thread. In this project a plain
    /// `async` function would run on the caller's thread, i.e. the main thread when
    /// called from the ViewModel, and parsing would then block the UI (W-15).
    ///
    /// `maxCacheAge` is the refresh setting (W-04): a saved forecast younger than this many seconds is
    /// returned at once, with no request, no new save and no "stale" reason (it is fresh enough).
    /// `nil` never reuses the saved copy, so the app always asks SMHI (pull to refresh, "Try again").
    @concurrent
    func forecast(
        for coordinate: Coordinate,
        reusingCacheYoungerThan maxCacheAge: TimeInterval? = nil
    ) async throws(WeatherError) -> ForecastResult {
        // Loaded once: used to reuse a fresh copy, and as the fallback if the request fails.
        let cached = cache.load(for: coordinate)

        if let maxCacheAge, let cached, isFresh(cached, maxAge: maxCacheAge) {
            // `fetchedAt` stays the original time, so the screen can say when the data really came.
            return ForecastResult(forecast: cached.forecast, fetchedAt: cached.fetchedAt, staleReason: nil)
        }

        do {
            return try await fetchFresh(for: coordinate)
        } catch {
            // Any failure: showing the last good forecast with an explanation is better
            // than an empty screen (W-10, W-16). Only without a cache does the error reach the UI.
            guard let cached else { throw error }
            return ForecastResult(forecast: cached.forecast, fetchedAt: cached.fetchedAt, staleReason: error)
        }
    }

    /// Younger than the limit, and not from the future: a `fetchedAt` after "now" means the phone's clock
    /// was set back, and a copy of unknown age must not be trusted. Exactly at the limit counts as old.
    private func isFresh(_ cached: CachedForecast, maxAge: TimeInterval) -> Bool {
        let age = now().timeIntervalSince(cached.fetchedAt)
        return age >= 0 && age < maxAge
    }

    /// The saved forecast for a place, without any network request. Used by the favourites list
    /// to show a last known temperature, also offline.
    func cachedForecast(for coordinate: Coordinate) -> CachedForecast? {
        cache.load(for: coordinate)
    }

    private func fetchFresh(for coordinate: Coordinate) async throws(WeatherError) -> ForecastResult {
        let data = try await apiClient.fetchForecastData(for: coordinate)

        let forecast: Forecast
        do {
            forecast = try parser.parse(data)
        } catch {
            throw WeatherError(error)
        }

        // Saved only after parsing succeeded, so a broken response never replaces a good cache.
        let fetchedAt = now()
        cache.save(CachedForecast(forecast: forecast, fetchedAt: fetchedAt), for: coordinate)
        return ForecastResult(forecast: forecast, fetchedAt: fetchedAt, staleReason: nil)
    }
}
