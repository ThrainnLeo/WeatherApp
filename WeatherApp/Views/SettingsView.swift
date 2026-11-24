import SwiftUI

/// The settings screen (W-04), shown as a sheet over the main screen like the favourites.
/// Both choices are stored with `@AppStorage`, so they survive a restart and the rest of the app
/// reads them from the same keys.
struct SettingsView: View {
    /// The day or night sky of the screen behind the sheet. The sheet sets its own colour scheme from it,
    /// for the same reason as `FavoritesView`: the screen behind may be dark while the sky is light.
    let sky: WeatherTheme

    @AppStorage(RefreshPolicy.key) private var refreshPolicy = RefreshPolicy.defaultValue
    @AppStorage(WeatherBackground.animatedKey) private var animatedBackground = true

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
        }
        .preferredColorScheme(sky.colorScheme)
    }
}

#Preview("Night") {
    SettingsView(sky: .night)
}

#Preview("Day") {
    SettingsView(sky: .day)
}
