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
    @State private var searchViewModel = SearchViewModel(
        repository: WeatherRepository(apiClient: SMHIAPIClient(), cache: UserDefaultsCacheStore()),
        placeRepository: PlaceRepository(client: MapsCoGeocodingClient())
    )

    var body: some Scene {
        WindowGroup {
            SearchView(viewModel: searchViewModel)
        }
    }
}
