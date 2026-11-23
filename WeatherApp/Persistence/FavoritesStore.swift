import Foundation

/// Keeps the user's favourite places between launches (W-03). A protocol so tests can use an
/// in-memory fake and the storage can change without touching the ViewModel.
nonisolated protocol FavoritesStore: Sendable {
    func load() -> [Place]
    func save(_ places: [Place])
}
