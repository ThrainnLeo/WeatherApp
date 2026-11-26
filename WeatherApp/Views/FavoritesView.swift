import SwiftUI

/// The quick-access list of favourite places (W-03), shown as a sheet over the main screen.
/// Tapping a place closes the sheet and loads its forecast; swiping left deletes it.
struct FavoritesView: View {
    let viewModel: FavoritesViewModel
    /// The day or night sky of the screen behind the sheet. The sheet sets its own colour scheme
    /// from it: the main screen may be dark (a weather theme) while the sky is day, and a light
    /// gradient with white text, or the other way round, would be unreadable.
    let sky: WeatherTheme
    /// What happens when a place is tapped. The sheet doesn't know about `SearchViewModel`;
    /// `SearchView` decides, which keeps this view reusable and the ViewModels separate.
    let onOpen: (Place) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    ContentUnavailableView(
                        "No favourites yet",
                        systemImage: "star",
                        description: Text("Tap ★ on a forecast to add one.")
                    )
                } else {
                    List {
                        // `frostedRows()` sets the row background, which SwiftUI reads per section,
                        // so it goes on the Section, not on the List (same as SearchView).
                        Section {
                            ForEach(viewModel.favorites) { place in
                                Button {
                                    onOpen(place)
                                    dismiss()
                                } label: {
                                    row(for: place)
                                }
                                .tint(.primary)
                            }
                            .onDelete { viewModel.remove(at: $0) }
                        }
                        .frostedRows()
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background {
                // Gradient only: the main screen is the one with moving layers.
                WeatherBackground(theme: sky, isAnimated: false)
            }
            .navigationTitle("Favourites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(sky.colorScheme)
    }

    private func row(for place: Place) -> some View {
        HStack {
            PlaceRowView(place: place)
                .frame(maxWidth: .infinity, alignment: .leading)
            // Decision 5: last known temperature from the cache, no network request.
            if let temperature = viewModel.lastKnownTemperature(for: place) {
                Text(TemperatureText.format(temperature))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }
}

/// In-memory store for previews only, so previews never touch the app's saved favourites.
private struct PreviewFavoritesStore: FavoritesStore {
    let places: [Place]
    func load() -> [Place] { places }
    func save(_ places: [Place]) {}
}

#Preview("With favourites") {
    let places = [
        Place(name: "Stockholm", detail: "Stockholms kommun, Stockholms län, Sverige",
              coordinate: Coordinate(latitude: 59.3251, longitude: 18.0711)),
        Place(name: "Kiruna", detail: "Kiruna kommun, Norrbottens län, Sverige",
              coordinate: Coordinate(latitude: 67.8558, longitude: 20.2253)),
        Place(name: "59.33, 18.07", detail: "", coordinate: Coordinate(latitude: 59.33, longitude: 18.07)),
    ]
    let viewModel = FavoritesViewModel(
        store: PreviewFavoritesStore(places: places),
        repository: WeatherRepository(apiClient: SMHIAPIClient(), cache: UserDefaultsCacheStore())
    )
    return FavoritesView(viewModel: viewModel, sky: .night) { _ in }
}

#Preview("With favourites, day") {
    let places = [
        Place(name: "Stockholm", detail: "Stockholms kommun, Stockholms län, Sverige",
              coordinate: Coordinate(latitude: 59.3251, longitude: 18.0711)),
        Place(name: "Kiruna", detail: "Kiruna kommun, Norrbottens län, Sverige",
              coordinate: Coordinate(latitude: 67.8558, longitude: 20.2253)),
    ]
    let viewModel = FavoritesViewModel(
        store: PreviewFavoritesStore(places: places),
        repository: WeatherRepository(apiClient: SMHIAPIClient(), cache: UserDefaultsCacheStore())
    )
    return FavoritesView(viewModel: viewModel, sky: .day) { _ in }
}

#Preview("Empty") {
    let viewModel = FavoritesViewModel(
        store: PreviewFavoritesStore(places: []),
        repository: WeatherRepository(apiClient: SMHIAPIClient(), cache: UserDefaultsCacheStore())
    )
    return FavoritesView(viewModel: viewModel, sky: .night) { _ in }
}
