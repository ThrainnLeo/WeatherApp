import Foundation
import Testing
@testable import WeatherApp

/// `FavoritesViewModel` lives on the main actor, so the tests do too.
@MainActor
struct FavoritesViewModelTests {
    // MARK: - F3: star on, star off

    @Test func toggleAddsAndSecondToggleRemoves() {
        let store = FakeFavoritesStore()
        let viewModel = makeViewModel(store: store)

        viewModel.toggle(stockholm)
        #expect(viewModel.favorites == [stockholm])
        #expect(store.lastSaved == [stockholm])

        viewModel.toggle(stockholm)
        #expect(viewModel.favorites.isEmpty)
        #expect(store.lastSaved.isEmpty)
    }

    // MARK: - F4: no duplicates

    @Test func sameCoordinatesTwiceGiveOneEntry() {
        let viewModel = makeViewModel(store: FakeFavoritesStore())
        // The same city found once by name and once by coordinates.
        let byCoordinates = Place(
            name: "59.33, 18.07", detail: "",
            coordinate: Coordinate(latitude: 59.33, longitude: 18.07)
        )

        viewModel.toggle(stockholm)
        #expect(viewModel.favorites.count == 1)
        // The star for the coordinate search already shows as filled...
        #expect(viewModel.isFavorite(byCoordinates))

        viewModel.toggle(byCoordinates)

        // ...so tapping it finds "the same place" and removes it; there is never a second copy.
        #expect(viewModel.favorites.isEmpty)
    }

    // MARK: - F5: a few hundred metres away counts as the same place

    @Test func placeAFewHundredMetresAwayIsAFavorite() {
        let viewModel = makeViewModel(store: FakeFavoritesStore([stockholm]))
        // About 400 m from `stockholm` (59.3293, 18.0686): both round to 59.33, 18.07.
        let nearby = Place(
            name: "Gamla stan", detail: "Stockholm",
            coordinate: Coordinate(latitude: 59.3260, longitude: 18.0700)
        )

        #expect(viewModel.isFavorite(nearby))
    }

    // MARK: - F6: swipe to delete

    @Test func removeAtOffsetsRemovesThatPlaceAndSaves() {
        let store = FakeFavoritesStore([stockholm, kiruna, gothenburg])
        let viewModel = makeViewModel(store: store)

        viewModel.remove(at: IndexSet(integer: 1))

        #expect(viewModel.favorites == [stockholm, gothenburg])
        #expect(store.lastSaved == [stockholm, gothenburg])
        #expect(store.saveCount == 1)
    }

    // MARK: - F7: clearing the saved forecasts (W-04)

    @Test func clearingSavedForecastsRemovesTheTemperatureButKeepsTheFavourites() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let step = ForecastStep(
            time: now, intervalStart: now, temperature: 7, condition: .clearSky,
            windSpeed: nil, windGust: nil, windDirection: nil,
            precipitation: nil, precipitationProbability: nil, humidity: nil
        )
        let saved = CachedForecast(
            forecast: Forecast(latitude: 59.33, longitude: 18.07, issuedAt: now, steps: [step]),
            fetchedAt: now
        )
        let repository = WeatherRepository(
            apiClient: FakeAPIClient(.failure(.offline)),
            cache: FakeCacheStore(prefilled: [stockholm.coordinate: saved])
        )
        let viewModel = FavoritesViewModel(store: FakeFavoritesStore([stockholm]), repository: repository)
        #expect(viewModel.lastKnownTemperature(for: stockholm, now: now) == 7)

        repository.clearSavedForecasts()

        // The row then shows no temperature (the view hides a `nil`), and the favourite itself stays.
        #expect(viewModel.lastKnownTemperature(for: stockholm, now: now) == nil)
        #expect(viewModel.favorites == [stockholm])
    }

    // MARK: - Helpers

    private func makeViewModel(store: FakeFavoritesStore) -> FavoritesViewModel {
        // The repository is only used for `lastKnownTemperature`; fakes keep the network out.
        let repository = WeatherRepository(
            apiClient: FakeAPIClient(.failure(.offline)),
            cache: FakeCacheStore()
        )
        return FavoritesViewModel(store: store, repository: repository)
    }
}

private let stockholm = Place(
    name: "Stockholm", detail: "Stockholms kommun, Sverige",
    coordinate: Coordinate(latitude: 59.3293, longitude: 18.0686)
)
private let kiruna = Place(
    name: "Kiruna", detail: "Kiruna kommun, Sverige",
    coordinate: Coordinate(latitude: 67.8558, longitude: 20.2253)
)
private let gothenburg = Place(
    name: "Göteborg", detail: "Göteborgs Stad, Sverige",
    coordinate: Coordinate(latitude: 57.7072, longitude: 11.9670)
)
