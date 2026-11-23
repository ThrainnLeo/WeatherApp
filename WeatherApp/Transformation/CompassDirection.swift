import Foundation

/// Turns a wind direction in degrees into one of 8 compass points, e.g. 306° → "NW" (W-02).
///
/// SMHI's `wind_from_direction` is where the wind comes *from*, which is also how wind is
/// named in everyday speech: a "north wind" (N) blows from the north.
nonisolated enum CompassDirection {
    private static let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

    static func abbreviation(forDegrees degrees: Double) -> String {
        // `Int(_:)` crashes on NaN or infinity, so those never reach the maths below.
        guard degrees.isFinite else { return "–" }

        // Wrap into 0..<360, also for negative values (-90° is the same as 270°).
        let wrapped = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)

        // Each point covers 45°, centred on it: N is 337.5°–22.5°. Shifting by half a sector
        // (22.5°) before dividing makes 359° land in N instead of NW. `% 8` turns the
        // ninth sector (337.5°+ shifted past 360°) back into N.
        let index = Int((wrapped + 22.5) / 45) % points.count
        return points[index]
    }
}
