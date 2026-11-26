import Foundation
import Testing
@testable import WeatherApp

/// `SearchViewModel` lives on the main actor, so the tests do too. They use the real repository with
/// fakes for SMHI and for the saved forecasts, and count how many requests SMHI gets.
@MainActor
struct SearchViewModelTests {
    let stockholm = Place(
        name: "Stockholm", detail: "Sverige",
        coordinate: Coordinate(latitude: 59.33, longitude: 18.07)
    )
    /// The fixed "now" of both clocks (the repository's and the ViewModel's).
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - V1-V3: choosing a place follows the refresh setting (W-04)

    @Test func choosingAPlaceWithAFreshSavedForecastMakesNoRequest() async {
        let (viewModel, api) = makeViewModel(savedAge: 600, policy: .hour1)

        viewModel.select(stockholm)
        await waitForLoad(of: viewModel)

        #expect(viewModel.isLoaded)
        #expect(api.callCount == 0)
    }

    @Test func choosingAPlaceWithAnOldSavedForecastAsksSMHI() async {
        let (viewModel, api) = makeViewModel(savedAge: 7200, policy: .hour1)

        viewModel.select(stockholm)
        await waitForLoad(of: viewModel)

        #expect(viewModel.isLoaded)
        #expect(api.callCount == 1)
    }

    @Test func neverReusingMeansAFreshSavedForecastIsStillFetchedAgain() async {
        let (viewModel, api) = makeViewModel(savedAge: 60, policy: .always)

        viewModel.select(stockholm)
        await waitForLoad(of: viewModel)

        #expect(api.callCount == 1)
    }

    // MARK: - V4: pulling down always asks SMHI

    @Test func pullToRefreshAsksSMHIEvenWhenTheSavedForecastIsFresh() async {
        let (viewModel, api) = makeViewModel(savedAge: 600, policy: .hour1)
        viewModel.select(stockholm)
        await waitForLoad(of: viewModel)
        #expect(api.callCount == 0)

        await viewModel.refresh()

        #expect(api.callCount == 1)
    }

    // MARK: - Helpers

    private func makeViewModel(
        savedAge: TimeInterval, policy: RefreshPolicy
    ) -> (SearchViewModel, FakeAPIClient) {
        let saved = CachedForecast(forecast: makeForecast(), fetchedAt: now.addingTimeInterval(-savedAge))
        let cache = FakeCacheStore(prefilled: [stockholm.coordinate: saved])
        let api = FakeAPIClient(.success(validJSON))
        let repository = WeatherRepository(apiClient: api, cache: cache, now: { [now] in now })
        let viewModel = SearchViewModel(
            repository: repository,
            placeRepository: PlaceRepository(client: UnusedGeocodingClient()),
            now: { [now] in now },
            refreshPolicy: { policy }
        )
        return (viewModel, api)
    }

    /// `select` starts the request in a `Task` and returns at once, so the test waits (up to 3 seconds)
    /// until the state is no longer `.loading`.
    private func waitForLoad(of viewModel: SearchViewModel) async {
        for _ in 0..<300 {
            guard case .loading = viewModel.state else { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

private extension SearchViewModel {
    var isLoaded: Bool {
        if case .loaded = state { true } else { false }
    }
}

/// These tests never search for a place name, so the geocoder must not be called.
private struct UnusedGeocodingClient: GeocodingClient {
    func searchData(for query: String) async throws(WeatherError) -> Data {
        throw .network
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

/// A forecast that is clearly different from `validJSON`, to stand for the saved copy.
private func makeForecast() -> Forecast {
    let time = Date(timeIntervalSince1970: 1_799_900_000)
    let step = ForecastStep(
        time: time, intervalStart: time, temperature: -2, condition: .overcast,
        windSpeed: nil, windGust: nil, windDirection: nil,
        precipitation: nil, precipitationProbability: nil, humidity: nil
    )
    return Forecast(latitude: 59.33, longitude: 18.07, issuedAt: time, steps: [step])
}
