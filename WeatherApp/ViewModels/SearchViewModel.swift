import Foundation
import Observation

/// State and actions for the search screen (W-01). Talks to the repository; never navigates.
@Observable
@MainActor
final class SearchViewModel {
    var latitudeText = ""
    var longitudeText = ""
    private(set) var state: LoadState = .idle

    private let repository: WeatherRepository
    private let grouper: ForecastGrouper
    private let now: () -> Date

    /// The running request, so a new search can cancel it.
    private var currentTask: Task<Void, Never>?
    /// Identifies the newest request. A result is only shown if it still belongs to this ID.
    private var latestRequestID = UUID()
    /// The place currently shown, so pull to refresh knows what to reload.
    private var lastCoordinate: Coordinate?

    init(repository: WeatherRepository, grouper: ForecastGrouper = ForecastGrouper(), now: @escaping () -> Date = { Date() }) {
        self.repository = repository
        self.grouper = grouper
        self.now = now
    }

    /// Validates the text fields and loads a new place. The old place's data is cleared first.
    func search() {
        switch CoordinateInput.validate(latitude: latitudeText, longitude: longitudeText) {
        case .failure(let error):
            cancelPendingRequest()
            state = .failed(UserMessages.message(for: error))
        case .success(let coordinate):
            state = .loading
            load(coordinate)
        }
    }

    /// Reloads the current place without clearing it, for pull to refresh. Returns when done,
    /// which is what SwiftUI's `.refreshable` waits for.
    func refresh() async {
        guard let lastCoordinate else { return }
        await load(lastCoordinate).value
    }

    @discardableResult
    private func load(_ coordinate: Coordinate) -> Task<Void, Never> {
        cancelPendingRequest()
        let requestID = UUID()
        latestRequestID = requestID
        lastCoordinate = coordinate

        let task = Task {
            let newState: LoadState
            // `throws(WeatherError)` tells the compiler the catch only ever gets a WeatherError.
            do throws(WeatherError) {
                let result = try await repository.forecast(for: coordinate)
                newState = .loaded(makeDisplay(from: result))
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

    private func makeDisplay(from result: ForecastResult) -> ForecastDisplay {
        let currentTime = now()
        return ForecastDisplay(
            grouped: grouper.group(result.forecast, now: currentTime),
            fetchedAt: result.fetchedAt,
            staleMessage: result.staleReason.map {
                UserMessages.staleBanner(reason: $0, fetchedAt: result.fetchedAt, now: currentTime)
            }
        )
    }
}
