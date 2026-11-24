//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Thrainn Leo Thorisson on 2026-11-19.
//

import SwiftUI

@main
struct WeatherAppApp: App {
    // The real dependencies are created once here and passed down; tests build their own with fakes.
    // One repository for both ViewModels, so the favourites list reads the same forecast cache
    // that searches fill.
    private static let repository = WeatherRepository(apiClient: SMHIAPIClient(), cache: UserDefaultsCacheStore())

    @State private var searchViewModel = SearchViewModel(
        repository: WeatherAppApp.repository,
        placeRepository: PlaceRepository(client: MapsCoGeocodingClient())
    )
    @State private var favoritesViewModel = FavoritesViewModel(
        store: UserDefaultsFavoritesStore(),
        repository: WeatherAppApp.repository
    )

    @State private var settingsViewModel = SettingsViewModel(repository: WeatherAppApp.repository)

    var body: some Scene {
        WindowGroup {
            SearchView(
                viewModel: searchViewModel,
                favoritesViewModel: favoritesViewModel,
                settingsViewModel: settingsViewModel
            )
        }
    }
}
