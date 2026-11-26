import Foundation

/// The fixed start values of one cloud, raindrop, snowflake or star in the animated background.
///
/// Nothing here changes while the app runs: where an element is at a given moment is worked out from
/// these values and the time (see `WeatherMotion`), so there is no state to keep per frame.
nonisolated struct WeatherParticle: Equatable, Sendable {
    /// Where it sits across its direction of travel, 0...1 (x for rain and snow, y for clouds).
    let lane: Double
    /// How far into its cycle it starts, 0...1, so the elements don't all start at the same edge.
    let start: Double
    /// Speed in points per second.
    let speed: Double
    /// Size in points (the width of a cloud, the length of a raindrop, the diameter of a flake or star).
    let size: Double
    /// An offset in radians, 0..<2π, so sway and twinkle of different elements are out of step.
    let phase: Double

    /// `count` elements with start values drawn from `seed`. The same seed always gives the same elements.
    static func field(
        count: Int, seed: UInt64, speed: ClosedRange<Double>, size: ClosedRange<Double>
    ) -> [WeatherParticle] {
        var generator = SeededGenerator(seed: seed)
        return (0..<max(0, count)).map { _ in
            WeatherParticle(
                lane: .random(in: 0...1, using: &generator),
                start: .random(in: 0...1, using: &generator),
                speed: .random(in: speed, using: &generator),
                size: .random(in: size, using: &generator),
                phase: .random(in: 0...(2 * .pi), using: &generator)
            )
        }
    }

    // One pool per kind, as big as the biggest theme needs. A layer takes the first `count` of its
    // pool, so a cloud keeps its size and speed whichever theme it is drawn for. Speeds: clouds drift
    // slowly, snow floats, rain falls fast.
    static let clouds = field(count: 4, seed: 33, speed: 6...14, size: 90...170)
    static let rain = field(count: 70, seed: 11, speed: 420...620, size: 10...18)
    static let snow = field(count: 36, seed: 22, speed: 22...45, size: 2...4.5)
    /// Stars stand still; they only twinkle.
    static let stars = field(count: 55, seed: 44, speed: 0...0, size: 1...2.2)
}
