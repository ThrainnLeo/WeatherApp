import Foundation
import Observation

/// The actions of the settings screen that need data (W-04). The two choices (refresh and animation)
/// are plain `@AppStorage` in the view; only clearing the saved forecasts goes through here, so the
/// View never touches the repository.
@Observable
@MainActor
final class SettingsViewModel {
    private let repository: WeatherRepository

    init(repository: WeatherRepository) {
        self.repository = repository
    }

    /// Forgets every saved forecast. Favourites are kept; their last known temperature disappears
    /// until the place is loaded again, because it was read from the saved forecast.
    func clearSavedForecasts() {
        repository.clearSavedForecasts()
    }
}
