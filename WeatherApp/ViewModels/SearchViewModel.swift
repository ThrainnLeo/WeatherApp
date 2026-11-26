import Foundation
import Observation

/// State and actions for the search screen (W-01, W-08). Talks to the repositories; never navigates.
@Observable
@MainActor
final class SearchViewModel {
    var inputMode: InputMode = .place

    // Place mode
    var placeQuery = ""
    private(set) var placeSearch: PlaceSearchState = .idle

    // Coordinates mode
    var latitudeText = ""
    var longitudeText = ""

    /// The forecast part of the screen, shared by both modes.
    private(set) var state: LoadState = .idle

    /// The place whose forecast is loading or shown, so the star button knows what to save (W-03).
    /// For a coordinate search it is a `Place` named after its coordinates.
    private(set) var currentPlace: Place?

    private let repository: WeatherRepository
    private let placeRepository: PlaceRepository
    private let grouper: ForecastGrouper
    private let now: () -> Date
    /// The refresh setting (W-04): how old a saved forecast may be and still be shown without a request.
    /// Injected like `now`, so a test can say "the user chose 15 minutes".
    private let refreshPolicy: () -> RefreshPolicy

    /// The running forecast request, so a new search can cancel it.
    private var currentTask: Task<Void, Never>?
    /// Identifies the newest forecast request. A result is only shown if it still belongs to this ID.
    private var latestRequestID = UUID()
    /// The place currently shown, so pull to refresh knows what to reload.
    private var lastCoordinate: Coordinate?
    private var lastTitle = ""

    /// Same race guard as for the forecast, but for place searches.
    private var placeTask: Task<Void, Never>?
    private var latestPlaceRequestID = UUID()

    init(
        repository: WeatherRepository,
        placeRepository: PlaceRepository,
        grouper: ForecastGrouper = ForecastGrouper(),
        now: @escaping () -> Date = { Date() },
        refreshPolicy: @escaping () -> RefreshPolicy = { RefreshPolicy.stored() }
    ) {
        self.repository = repository
        self.placeRepository = placeRepository
        self.grouper = grouper
        self.now = now
        self.refreshPolicy = refreshPolicy
    }

    // MARK: - Place mode

    /// Looks up the typed name. The current forecast stays visible until a place is chosen.
    func searchPlaces() {
        let query = placeQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        placeTask?.cancel()
        latestPlaceRequestID = UUID()
        guard !query.isEmpty else {
            placeSearch = .failed(UserMessages.emptyPlaceQuery)
            return
        }

        placeSearch = .searching
        let requestID = latestPlaceRequestID
        placeTask = Task {
            let newState: PlaceSearchState
            do throws(WeatherError) {
                let places = try await placeRepository.search(query)
                newState = places.isEmpty ? .noResults(UserMessages.noPlacesFound(for: query)) : .results(places)
            } catch {
                if error == .cancelled { return }
                newState = .failed(UserMessages.message(for: error))
            }
            guard requestID == latestPlaceRequestID else { return }
            placeSearch = newState
        }
    }

    /// Loads the forecast for a place from the result list. A place outside SMHI's area
    /// (e.g. Paris) is allowed here; SMHI's answer becomes the "outside the forecast area" message.
    func select(_ place: Place) {
        placeTask?.cancel()
        latestPlaceRequestID = UUID()
        placeSearch = .idle
        placeQuery = place.name
        currentPlace = place
        state = .loading
        load(
            place.coordinate,
            title: place.detail.isEmpty ? place.name : "\(place.name), \(place.detail)",
            reusingSavedForecast: true
        )
    }

    /// Opens a favourite: the same path as choosing a place from the search results.
    func open(_ favorite: Place) {
        select(favorite)
    }

    // MARK: - Coordinates mode

    /// Validates the text fields and loads a new place. The old place's data is cleared first.
    func search() {
        switch CoordinateInput.validate(latitude: latitudeText, longitude: longitudeText) {
        case .failure(let error):
            cancelPendingRequest()
            // Forget the previous place, so "Try again" can't reload it by mistake.
            lastCoordinate = nil
            currentPlace = nil
            state = .failed(UserMessages.message(for: error))
        case .success(let coordinate):
            let title = Self.title(for: coordinate)
            // Decision 3: coordinate searches can be favourites, named after their coordinates.
            currentPlace = Place(name: title, detail: "", coordinate: coordinate)
            state = .loading
            load(coordinate, title: title, reusingSavedForecast: true)
        }
    }

    // MARK: - Shared

    /// "Try again" after an error: reloads the place that failed, or re-checks the typed coordinates.
    func retry() {
        guard let lastCoordinate else {
            search()
            return
        }
        state = .loading
        // The user asked again, so the saved forecast is not reused: always ask SMHI.
        load(lastCoordinate, title: lastTitle, reusingSavedForecast: false)
    }

    /// Reloads the current place without clearing it, for pull to refresh. Returns when done,
    /// which is what SwiftUI's `.refreshable` waits for. Pulling down always asks SMHI, whatever the setting.
    func refresh() async {
        guard let lastCoordinate else { return }
        await load(lastCoordinate, title: lastTitle, reusingSavedForecast: false).value
    }

    /// `reusingSavedForecast`: `true` when the user *chose* a place (the refresh setting decides if a
    /// saved forecast is fresh enough to show); `false` when the user *asked for new data* (pull to
    /// refresh, "Try again").
    @discardableResult
    private func load(
        _ coordinate: Coordinate, title: String, reusingSavedForecast: Bool
    ) -> Task<Void, Never> {
        cancelPendingRequest()
        let requestID = UUID()
        latestRequestID = requestID
        lastCoordinate = coordinate
        lastTitle = title
        // Read here, on the main actor, so the choice at the moment of the tap is the one that counts.
        let maxCacheAge: TimeInterval? = reusingSavedForecast ? refreshPolicy().maxCacheAge : nil

        let task = Task {
            let newState: LoadState
            // `throws(WeatherError)` tells the compiler the catch only ever gets a WeatherError.
            do throws(WeatherError) {
                let result = try await repository.forecast(for: coordinate, reusingCacheYoungerThan: maxCacheAge)
                newState = .loaded(makeDisplay(from: result, title: title))
            } catch {
                // A newer search replaced this one; there is nothing to tell the user.
                if error == .cancelled { return }
                newState = .failed(UserMessages.message(for: error))
            }

            // Race guard (Q12): a newer search may have started while we were waiting.
            // Cancelling is not enough, because the repository can still return cached data
            // for a cancelled request, so the result is dropped unless it is still the newest.
            guard requestID == latestRequestID else { return }
            state = newState
        }
        currentTask = task
        return task
    }

    private func cancelPendingRequest() {
        currentTask?.cancel()
        currentTask = nil
        // A new ID makes any result still on its way count as outdated.
        latestRequestID = UUID()
    }

    private func makeDisplay(from result: ForecastResult, title: String) -> ForecastDisplay {
        let currentTime = now()
        return ForecastDisplay(
            title: title,
            grouped: grouper.group(result.forecast, now: currentTime),
            fetchedAt: result.fetchedAt,
            staleMessage: result.staleReason.map {
                UserMessages.staleBanner(reason: $0, fetchedAt: result.fetchedAt, now: currentTime)
            }
        )
    }

    /// Always with a decimal point, so "59.33, 18.07" can't be misread as four numbers
    /// the way "59,33, 18,07" could on a Swedish phone.
    private static func title(for coordinate: Coordinate) -> String {
        String(format: "%.2f, %.2f", coordinate.latitude, coordinate.longitude)
    }
}
