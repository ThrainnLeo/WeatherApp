import Foundation
import Testing
@testable import WeatherApp

/// Runs against a throwaway `UserDefaults` suite, so the app's real favourites are never touched.
struct FavoritesStoreTests {
    // MARK: - F1: round trip

    @Test func savedPlacesLoadBackInTheSameOrder() throws {
        let (defaults, suiteName) = try makeThrowawayDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsFavoritesStore(defaults: defaults)
        let places = [kiruna, stockholm, coordinatesOnly]

        store.save(places)

        #expect(store.load() == places)
    }

    // MARK: - F2: corrupt data

    @Test func corruptDataLoadsAsEmptyList() throws {
        let (defaults, suiteName) = try makeThrowawayDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not json".utf8), forKey: UserDefaultsFavoritesStore.key)

        let store = UserDefaultsFavoritesStore(defaults: defaults)

        #expect(store.load().isEmpty)
    }
}

// MARK: - Helpers

private func makeThrowawayDefaults() throws -> (UserDefaults, String) {
    let suiteName = "FavoritesStoreTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    return (defaults, suiteName)
}

private let stockholm = Place(
    name: "Stockholm", detail: "Stockholms kommun, Sverige",
    coordinate: Coordinate(latitude: 59.3251, longitude: 18.0711)
)
private let kiruna = Place(
    name: "Kiruna", detail: "Kiruna kommun, Sverige",
    coordinate: Coordinate(latitude: 67.8558, longitude: 20.2253)
)
private let coordinatesOnly = Place(
    name: "57.71, 11.97", detail: "",
    coordinate: Coordinate(latitude: 57.71, longitude: 11.97)
)
