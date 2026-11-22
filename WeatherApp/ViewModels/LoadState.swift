import Foundation

/// Everything the search screen can be showing. Exactly one case at a time,
/// so the View can never show a spinner and an error together.
enum LoadState: Equatable {
    /// Nothing searched yet.
    case idle
    /// Waiting for the repository. The previous place's data is gone, so it can't be mistaken
    /// for the new place.
    case loading
    case loaded(ForecastDisplay)
    /// A message the user can read. Errors that should never be shown (`.cancelled`) don't get here.
    case failed(String)
}
