import Foundation

/// How each choice reads in the settings screen.
extension RefreshPolicy {
    /// Worded as "reuse a saved forecast for ...", because "refresh every hour" would sound like a timer,
    /// and this setting only decides when a saved forecast is too old.
    var title: String {
        switch self {
        case .always: "Never"
        case .minutes15: "15 minutes"
        case .hour1: "1 hour"
        case .hours3: "3 hours"
        }
    }
}
