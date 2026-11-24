import SwiftUI

/// The settings screen (W-04), shown as a sheet over the main screen like the favourites.
/// The two choices are stored with `@AppStorage`, so they survive a restart and the rest of the app
/// reads them from the same keys. Clearing the saved forecasts goes through the ViewModel.
struct SettingsView: View {
    let viewModel: SettingsViewModel
    /// The day or night sky of the screen behind the sheet. The sheet sets its own colour scheme from it,
    /// for the same reason as `FavoritesView`: the screen behind may be dark while the sky is light.
    let sky: WeatherTheme

    @AppStorage(RefreshPolicy.key) private var refreshPolicy = RefreshPolicy.defaultValue
    @AppStorage(WeatherBackground.animatedKey) private var animatedBackground = true

    /// Screen state only: whether the confirmation is showing, and whether to say "cleared".
    /// The "cleared" text is not kept in the ViewModel, which lives as long as the app and would show it
    /// the next time the sheet opens.
    @State private var confirmingClear = false
    @State private var didClear = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // `frostedRows()` sets the row background, which SwiftUI reads per section (same as SearchView).
                Section {
                    Picker("Reuse saved forecast for", selection: $refreshPolicy) {
                        ForEach(RefreshPolicy.allCases, id: \.self) { policy in
                            Text(policy.title).tag(policy)
                        }
                    }
                } footer: {
                    Text("A saved forecast younger than this is shown without asking SMHI again. “Never” always fetches new data. Pull down on the forecast to refresh at any time.")
                }
                .frostedRows()

                Section {
                    Toggle("Animated background", isOn: $animatedBackground)
                } footer: {
                    Text("Clouds, rain, snow and stars behind the forecast. Reduce Motion and Low Power Mode pause them anyway.")
                }
                .frostedRows()

                Section {
                    Button("Clear saved forecasts", role: .destructive) {
                        confirmingClear = true
                    }
                } footer: {
                    Text(didClear
                         ? "Saved forecasts cleared."
                         : "Saved forecasts are what a place shows when you are offline.")
                }
                .frostedRows()
            }
            .scrollContentBackground(.hidden)
            .background {
                // Gradient only: the main screen is the one with moving layers.
                WeatherBackground(theme: sky, isAnimated: false)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Asked first because it can't be undone: offline, a place shows nothing until it has been loaded again.
            .confirmationDialog("Clear saved forecasts?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear", role: .destructive) {
                    viewModel.clearSavedForecasts()
                    didClear = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Saved forecasts are used when you are offline. Favourites are kept. Offline, a place shows nothing until you have loaded it again.")
            }
        }
        .preferredColorScheme(sky.colorScheme)
    }
}

/// The previews clear nothing that matters: `UserDefaults.standard` of a preview process is not the app's.
private func makeViewModel() -> SettingsViewModel {
    SettingsViewModel(
        repository: WeatherRepository(apiClient: SMHIAPIClient(), cache: UserDefaultsCacheStore())
    )
}

#Preview("Night") {
    SettingsView(viewModel: makeViewModel(), sky: .night)
}

#Preview("Day") {
    SettingsView(viewModel: makeViewModel(), sky: .day)
}
