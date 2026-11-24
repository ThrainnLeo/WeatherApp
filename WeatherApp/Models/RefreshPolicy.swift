import Foundation

/// How old a saved forecast may be before the app fetches a new one (W-04).
///
/// "Refresh rate" here means the age of the saved copy, not a timer: SMHI renews its forecast about
/// once an hour, so asking more often returns the same data and only costs network and battery.
/// The raw value is the number of minutes, and the enum is `Int`-backed so that `@AppStorage` can
/// store it directly.
nonisolated enum RefreshPolicy: Int, CaseIterable, Sendable {
    case always = 0
    case minutes15 = 15
    case hour1 = 60
    case hours3 = 180

    /// The `UserDefaults` key shared by the settings screen and `stored(in:)`.
    static let key = "refreshPolicy"

    /// What a new install uses: SMHI's own forecast lives for about an hour.
    static let defaultValue = RefreshPolicy.hour1

    /// A saved forecast younger than this (in seconds) is shown without asking SMHI again.
    /// `.always` is 0, so nothing is ever young enough: that is how the app behaved before this setting.
    var maxCacheAge: TimeInterval {
        TimeInterval(rawValue) * 60
    }

    /// The saved choice. A tests passes its own `UserDefaults` so it never touches the app's real settings.
    static func stored(in defaults: UserDefaults = .standard) -> RefreshPolicy {
        // `object(forKey:)`, not `integer(forKey:)`: a missing key must give the default, and
        // `integer(forKey:)` would answer 0, which is "Always".
        guard let raw = defaults.object(forKey: key) as? Int else { return defaultValue }
        // An unknown number (a choice removed in a later version) also gives the default.
        return RefreshPolicy(rawValue: raw) ?? defaultValue
    }
}
