import Foundation
import Testing
@testable import WeatherApp

/// Runs against a throwaway `UserDefaults` suite, so the app's real saved forecasts are never touched.
struct UserDefaultsCacheStoreTests {
    // MARK: - C1: clearing removes the forecasts and nothing else

    @Test func removeAllForgetsEveryForecastAndKeepsOtherKeys() throws {
        let (defaults, suiteName) = try makeThrowawayDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsCacheStore(defaults: defaults)
        store.save(saved, for: stockholm)
        store.save(saved, for: kiruna)
        // The same `UserDefaults` also holds the favourites and the settings.
        defaults.set(Data("favourites".utf8), forKey: UserDefaultsFavoritesStore.key)
        defaults.set(15, forKey: RefreshPolicy.key)
        #expect(store.load(for: stockholm) == saved)

        store.removeAll()

        #expect(store.load(for: stockholm) == nil)
        #expect(store.load(for: kiruna) == nil)
        #expect(defaults.data(forKey: UserDefaultsFavoritesStore.key) != nil)
        #expect(defaults.integer(forKey: RefreshPolicy.key) == 15)
    }

    // MARK: - Helpers

    private func makeThrowawayDefaults() throws -> (UserDefaults, String) {
        let suiteName = "UserDefaultsCacheStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (defaults, suiteName)
    }
}

private let stockholm = Coordinate(latitude: 59.33, longitude: 18.07)
private let kiruna = Coordinate(latitude: 67.86, longitude: 20.23)

private let saved: CachedForecast = {
    let time = Date(timeIntervalSince1970: 1_800_000_000)
    let step = ForecastStep(
        time: time, intervalStart: time, temperature: 7, condition: .clearSky,
        windSpeed: nil, windGust: nil, windDirection: nil,
        precipitation: nil, precipitationProbability: nil, humidity: nil
    )
    return CachedForecast(
        forecast: Forecast(latitude: 59.33, longitude: 18.07, issuedAt: time, steps: [step]),
        fetchedAt: time
    )
}()
