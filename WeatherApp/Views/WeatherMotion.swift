import Foundation

/// The maths behind the animated background: where something that moves in a straight line is at a
/// given moment. Pure functions of time, so a frame needs no stored state and tests can ask for any moment.
nonisolated enum WeatherMotion {
    /// `value` brought into `0..<length`, also for negative values (`-1` in a length of `10` is `9`).
    /// Swift's `%` keeps the sign of the dividend, which is why this isn't just `value % length`.
    static func wrapped(_ value: Double, length: Double) -> Double {
        guard length > 0 else { return 0 }
        let remainder = value.truncatingRemainder(dividingBy: length)
        let result = remainder < 0 ? remainder + length : remainder
        // A tiny negative remainder can round up to exactly `length`; keep the range half-open.
        return result >= length ? 0 : result
    }

    /// Where something moving at constant `speed` is along an axis `extent` points long, `time` seconds in.
    ///
    /// The path is `extent` plus a `margin` on each side, so an element leaves the screen completely
    /// before it jumps back to the other side, and never appears or disappears in view.
    /// The result is in `-margin ..< extent + margin`.
    static func position(
        startFraction: Double, speed: Double, at time: Double, extent: Double, margin: Double
    ) -> Double {
        let cycle = extent + 2 * margin
        return wrapped(startFraction * cycle + speed * time, length: cycle) - margin
    }
}
