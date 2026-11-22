import Foundation

/// The place search's own state, separate from the forecast's `LoadState`, so the current
/// forecast stays on screen while the user looks for another place.
enum PlaceSearchState: Equatable {
    case idle
    case searching
    case results([Place])
    /// The search worked but found nothing; holds the message to show.
    case noResults(String)
    case failed(String)
}
