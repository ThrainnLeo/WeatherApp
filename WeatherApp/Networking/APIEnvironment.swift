import Foundation

/// The one place where server addresses live, so switching servers is a one-line change (W-19).
nonisolated enum APIEnvironment {
    static let smhiForecastBaseURL = "https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1"
}
