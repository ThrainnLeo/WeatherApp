import Foundation
import Synchronization
@testable import WeatherApp

/// An in-memory cache that also counts saves, so tests can check whether the cache was written.
///
/// The repository runs off the main thread, so the storage is guarded by a `Mutex`:
/// only one thread at a time can read or change it.
nonisolated final class FakeCacheStore: CacheStore {
    private let entries = Mutex<[Coordinate: CachedForecast]>([:])
    private let saves = Mutex(0)

    init(prefilled: [Coordinate: CachedForecast] = [:]) {
        entries.withLock { $0 = prefilled }
    }

    var saveCount: Int { saves.withLock { $0 } }

    func save(_ cached: CachedForecast, for coordinate: Coordinate) {
        entries.withLock { $0[coordinate] = cached }
        saves.withLock { $0 += 1 }
    }

    func load(for coordinate: Coordinate) -> CachedForecast? {
        entries.withLock { $0[coordinate] }
    }
}
