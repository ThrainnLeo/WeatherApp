import Foundation
import Testing
@testable import WeatherApp

struct WeatherRepositoryTests {
    let stockholm = Coordinate(latitude: 59.33, longitude: 18.07)
    /// The fixed "now" of the fake clock, so `fetchedAt` is predictable.
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    /// When the cached forecast in the tests was (pretend) downloaded.
    let yesterday = Date(timeIntervalSince1970: 1_800_000_000 - 86_400)

    // MARK: - R1: online

    @Test func successReturnsFreshForecastAndSavesIt() async throws {
        let cache = FakeCacheStore()
        let repository = makeRepository(api: FakeAPIClient(.success(validJSON)), cache: cache)

        let result = try await repository.forecast(for: stockholm)

        #expect(result.staleReason == nil)
        #expect(result.fetchedAt == now)
        #expect(result.forecast.steps.first?.temperature == 3.5)
        #expect(cache.load(for: stockholm) == CachedForecast(forecast: result.forecast, fetchedAt: now))
    }

    // MARK: - R2, R3: offline

    @Test func offlineWithCacheReturnsCachedForecast() async throws {
        let cached = CachedForecast(forecast: makeForecast(temperature: -2), fetchedAt: yesterday)
        let cache = FakeCacheStore(prefilled: [stockholm: cached])
        let repository = makeRepository(api: FakeAPIClient(.failure(.offline)), cache: cache)

        let result = try await repository.forecast(for: stockholm)

        #expect(result.forecast == cached.forecast)
        #expect(result.fetchedAt == yesterday)
        #expect(result.staleReason == .offline)
    }

    @Test func offlineWithoutCacheThrowsOffline() async {
        let repository = makeRepository(api: FakeAPIClient(.failure(.offline)), cache: FakeCacheStore())

        await #expect(throws: WeatherError.offline) {
            try await repository.forecast(for: stockholm)
        }
    }

    // MARK: - R4: broken response

    @Test func invalidJSONWithCacheReturnsCacheAndKeepsIt() async throws {
        let cached = CachedForecast(forecast: makeForecast(temperature: -2), fetchedAt: yesterday)
        let cache = FakeCacheStore(prefilled: [stockholm: cached])
        let repository = makeRepository(api: FakeAPIClient(.success(Data("not json".utf8))), cache: cache)

        let result = try await repository.forecast(for: stockholm)

        #expect(result.staleReason == .decoding)
        #expect(result.forecast == cached.forecast)
        #expect(cache.saveCount == 0)
        #expect(cache.load(for: stockholm) == cached)
    }

    // MARK: - R5, R6: server answers with an error

    @Test func outsideForecastAreaWithoutCacheThrowsThatError() async {
        let repository = makeRepository(api: FakeAPIClient(.failure(.outsideForecastArea)), cache: FakeCacheStore())

        await #expect(throws: WeatherError.outsideForecastArea) {
            try await repository.forecast(for: stockholm)
        }
    }

    @Test func serverErrorWithCacheReturnsCachedForecast() async throws {
        let cached = CachedForecast(forecast: makeForecast(temperature: -2), fetchedAt: yesterday)
        let cache = FakeCacheStore(prefilled: [stockholm: cached])
        let repository = makeRepository(api: FakeAPIClient(.failure(.http(500))), cache: cache)

        let result = try await repository.forecast(for: stockholm)

        #expect(result.staleReason == .http(500))
        #expect(result.forecast == cached.forecast)
    }

    // MARK: - Helpers

    private func makeRepository(api: FakeAPIClient, cache: FakeCacheStore) -> WeatherRepository {
        WeatherRepository(apiClient: api, cache: cache, now: { [now] in now })
    }
}

/// A minimal valid SMHI response with one step at 3.5 °C.
private let validJSON = Data("""
{
  "referenceTime": "2026-11-20T09:00:00Z",
  "geometry": { "type": "Point", "coordinates": [18.07, 59.33] },
  "timeSeries": [
    {
      "time": "2026-11-20T10:00:00Z",
      "intervalParametersStartTime": "2026-11-20T09:00:00Z",
      "data": { "air_temperature": 3.5, "symbol_code": 1 }
    }
  ]
}
""".utf8)

/// A forecast that is clearly different from `validJSON`, to stand for older cached data.
private func makeForecast(temperature: Double) -> Forecast {
    let time = Date(timeIntervalSince1970: 1_799_900_000)
    let step = ForecastStep(
        time: time,
        intervalStart: time,
        temperature: temperature,
        condition: .overcast,
        windSpeed: nil,
        windGust: nil,
        windDirection: nil,
        precipitation: nil,
        precipitationProbability: nil,
        humidity: nil
    )
    return Forecast(latitude: 59.33, longitude: 18.07, issuedAt: time, steps: [step])
}
