import Foundation
import Synchronization
@testable import WeatherApp

/// An in-memory favourites store that remembers what was saved last and how often,
/// so tests can check that the ViewModel saves every change.
nonisolated final class FakeFavoritesStore: FavoritesStore {
    private let stored: Mutex<[Place]>
    private let saves = Mutex(0)

    init(_ places: [Place] = []) {
        stored = Mutex(places)
    }

    var lastSaved: [Place] { stored.withLock { $0 } }
    var saveCount: Int { saves.withLock { $0 } }

    func load() -> [Place] {
        stored.withLock { $0 }
    }

    func save(_ places: [Place]) {
        stored.withLock { $0 = places }
        saves.withLock { $0 += 1 }
    }
}
